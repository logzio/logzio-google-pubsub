#!/bin/bash

# Declare default type
type="gcp-pubsub"


# Prints usage
# Output:
#   Help usage
function show_help () {
    echo -e "Usage: ./run.sh --listener_url=<listener_url> --token=<token> --region=<region> --type=<type>"
    echo -e " --listener_url=<listener_url>           Logz.io Listener URL (You can check it here https://docs.logz.io/user-guide/accounts/account-region.html)"
    echo -e " --token=<token>                     Logz.io token of the account you want to ship to."
    echo -e " --region=<region>                   Region where you want to upload Cloud Funtion."
    echo -e " --type=<type>                       Log type. Help classify logs into different classifications"
    echo -e " --help                              Show usage"
}

# Gets arguments
# Input:
#   Client's arguments ($@)
# Output:
#   listener_url - Logz.io Listener URL
#   token - Logz.io token of the account user want to ship to.
#   region - Region where user want to upload Cloud Funtion.
#   type -  Log type. Help classify logs into different classifications
# Error:
#   Exit Code 1

function get_arguments () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Getting arguments ..."
    while true; do
        case "$1" in
            --help)
                show_help
                exit
                ;;
            --listener_url=*)
                listener_url=$(echo "$1" | cut -d "=" -f2)
                if [[ "$listener_url" = "" ]]; then
                    echo -e "\033[0;31mrun.sh (1): no Logz.io Listener URL specified!\033[0;37m"
                    exit 1
                fi
                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] listener_url = $listener_url"
                ;;
            --token=*)
                token=$(echo "$1" | cut -d "=" -f2)
                if [[ "$token" = "" ]]; then
                    echo -e "\033[0;31mrun.sh (1): no Logz.io token specified!\033[0;37m"
                    exit 1
                fi
                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] token = $token"
                ;;
            --region=*)
                region=$(echo "$1" | cut -d "=" -f2)
                if [[ "$region" = "" ]]; then
                    echo -e "\033[0;31mrun.sh (1): no Google Cloud Region specified!\033[0;37m"
                    exit 1
                fi
                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] id = $token" 
                ;;
             --type=*)
                type=$(echo "$1" | cut -d "=" -f2)
                if [[ "$type" = "" ]]; then
                    echo -e "\033[0;31mrun.sh (1): Type will be assign gcp-pubsub!\033[0;37m"
					#Define default
					type="gcp-pubsub"
                fi
                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] type = $type" 
                ;;
            "")
                break
                ;;
            *)
                echo -e "\033[0;31m run.sh (1): unrecognized flag\033[0;37m"
                echo -e "\033[0;31ma run.sh (1): run.sh (1): try './run.sh --help' for more information\033[0;37m"
                exit 1
                ;;
        esac
        shift
    done
    check_validation
}

# Checks validation of the arguments
# Error:
#   Exit Code 1
function check_validation () {
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Checking validation ..."

    local is_error=false

    if [[ -z "$listener_url" ]]; then
        is_error=true
        echo -e "\033[0;31mrun.sh (1): Logz.io Listener URL must be specified\033[0;37m"
    fi
    if [[ -z "$token" ]]; then
        is_error=true
        echo -e "\033[0;31mrun.sh (1): Logz.io Token must be specified\033[0;37m"
    fi
    if [[ -z "$region" ]]; then
        is_error=true
        echo -e "\033[0;31mrun.sh (1): Region for Google Cloud Platform must be specified\033[0;37m"
    fi
    # if [[ -z "$type" ]]; then
    #     is_error=true
    #     echo -e "\033[0;31mrun.sh (1): Logz.io Type for logs must be specified\033[0;37m"
    # fi
  
    if $is_error; then
        echo -e "\033[0;31mrun.sh (1): try './run.sh --help' for more information\033[0;37m"
        exit 1
    fi

	echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Validation of arguments passed."
}

function populate_data_to_json (){
	echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Populating data to json ..."

	contents="$(jq --arg token "${token}" '.substitutions._LOGZIO_TOKEN = $token' config.json)"
    echo "${contents}" > config.json
	contents="$(jq  --arg type_of_log "${type}" '.substitutions._TYPE_NAME = $type_of_log' config.json)"
    echo "${contents}" > config.json
	contents="$(jq --arg region "${region}" '.substitutions._REGION = $region' config.json)"
    echo "${contents}" > config.json
	contents="$(jq --arg listener_url "${listener_url}" '.substitutions._LOGZIO_LISTENER = $listener_url' config.json)"
    echo "${contents}" > config.json

	echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Populate data to json finished."
}

function run_cloud_build(){
	
	echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Initialize Cloud Build ..."
	# Take project ID and project Number
	project_number="$(gcloud projects list \
	--filter="$(gcloud config get-value project)" \
	--format="value(PROJECT_NUMBER)")"
	project_id="$(gcloud config get-value project)"
 
	# Give permission for Cloud Build to assign proper roles
	cmd_enable_cloudresourcemanager="$(gcloud services enable cloudresourcemanager.googleapis.com)"
	cmd_enable_cloudbuild="$(gcloud services enable cloudbuild.googleapis.com)"
	cmd_enable_cloudfunction="$(gcloud services enable cloudfunctions.googleapis.com)"

	cmd_add_policy="$(gcloud projects add-iam-policy-binding $project_id --member serviceAccount:$project_number@cloudbuild.gserviceaccount.com --role roles/resourcemanager.projectIamAdmin)"
	cmd_enable_policy_function="$(gcloud iam service-accounts add-iam-policy-binding $project_id@appspot.gserviceaccount.com --member serviceAccount:$project_number@cloudbuild.gserviceaccount.com --role roles/iam.serviceAccountUser)"

	# Run project
	cmd_create_cloud_build="$(curl -X POST -T config.json -H "Authorization: Bearer $(gcloud config config-helper --format='value(credential.access_token)')" https://cloudbuild.googleapis.com/v1/projects/$project_id/builds)"

	echo "$cmd_create_cloud_build"
	echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Cloud Build Initialization is finished."
}

get_arguments "$@"
populate_data_to_json
run_cloud_build



