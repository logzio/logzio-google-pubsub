#!/bin/bash

# Declare default values
function_name="logzio_handler"
project_id=""
selected_projects=()
gcp_region=""
# Gets arguments
# Input:
#   Client's arguments ($@)
# Output:
#  gcp_region - Region where user want to upload Cloud Funtion.
#  function_name - Name of the Cloud Function. Default is 'logzioHandler'
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
            --gcp_region=*)
                gcp_region=$(echo "$1" | cut -d "=" -f2)
                if [[ "$gcp_region" = "" ]]; then
                    echo -e "\033[0;31mrun.sh (1): no Google Cloud Region specified!\033[0;37m"
                    exit 1
                fi
                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] gcp_region = $gcp_region" 
                ;;
             --function_name=*)
                function_name=$(echo "$1" | cut -d "=" -f2)
                if [[ "$function_name" = "" ]]; then
                    echo -e "\033[0;31mrun.sh (1): Function name will be assign logzioHandler\033[0;37m"
                    #Define default
                    function_name="logzioHandler"
                fi
                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] function_name = $function_name" 
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

    if [[ -z "$gcp_region" ]]; then
        is_error=true
        echo -e "\033[0;31mrun.sh (1): Region for Google Cloud Platform is missing please rerun the script with the relevant parameters\033[0;37m"
    fi

  
    if $is_error; then
        echo -e "\033[0;31mrun.sh (1): try './run.sh --help' for more information\033[0;37m"
        exit 1
    fi

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Validation of arguments passed."
}

# Populate data to json
function populate_data_to_json (){
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Populating data to json ..."

    contents="$(jq --arg gcp_region "${gcp_region}" '.substitutions._REGION = $gcp_region' config.json)"
    echo "${contents}" > config.json

    if [[ "$function_name" =~ ^logzio_* ]];
    then
        contents="$(jq --arg function_name "${function_name}" '.substitutions._FUNCTION_NAME = $function_name' config.json)"
        echo "${contents}" > config.json    
    else
        contents="$(jq --arg function_name "${function_name}" '.substitutions._FUNCTION_NAME = "logzio_"+$function_name' config.json)"
        echo "${contents}" > config.json
    fi

    contents="$(jq --arg topic_name "${function_name}" '.substitutions._PUBSUB_TOPIC_NAME = $topic_name+"-pubsub-topic-logs-to-logzio"' config.json)"
    echo "${contents}" > config.json
    contents="$(jq --arg subscription_prefix "${function_name}" '.substitutions._PUBSUB_SUBSCRIPTION_NAME = $subscription_prefix+"-pubsub-subscription-logs-to-logzio"' config.json)"
    echo "${contents}" > config.json
    contents="$(jq --arg sink_prefix "${function_name}" '.substitutions._SINK_NAME = $sink_prefix+"-sink-logs-to-logzio"' config.json)"
    echo "${contents}" > config.json

    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Populate data to json finished."
}

# Ping GCloud
# Output:
# Error:
#   Exit Code 1
function is_gcloud_install(){
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Running command gcloud -v .."

    gcloud_ping=`gcloud -v 2>/dev/null | wc -w`

    if [ $gcloud_ping -gt 0 ]
    then
        return
    else
        echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] Failed to get gcloud CLI. Please install Gcloud and login to proper account from where you want to send metrics..."
        exit 1	
    fi
}

# Init script with proper message and display active user account

function gcloud_init_confs(){
    user_active_account="$(gcloud auth list --filter=status:ACTIVE --format="value(account)")"
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Your active account [${user_active_account}]"
}

# Choose and set project id
# Error:
#   Exit Code 1
function choose_and_set_project_id(){
    array_projects=()
    selected_projects=()
    count=0
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Choose and set project ids ..."
    # List all projects and store them in an array
    for project in $(gcloud projects list --format="value(projectId)")
    do
        count=$((count + 1))
        echo "[$count]:  $project"
        array_projects+=("$project")
    done
    # Add the option to deploy to all projects
    echo "[$((count + 1))]:  All Projects"

    # Prompt the user to select multiple projects
    read -p "Please fill in the numbers of the projects where you would like the integration to be deployed, separated by spaces (or type 'all' to select all projects): " -a mainmenuinput

    # Validate and store selected projects
if [[ "${mainmenuinput[0]}" == "all" || "${mainmenuinput[0]}" -eq $((count + 1)) ]]; then
        selected_projects=("${array_projects[@]}")
    else
        for input in "${mainmenuinput[@]}"
        do
            if [[ $input -ge 1 && $input -le $count ]]; then
                selected_projects+=("${array_projects[$((input-1))]}")
            else
                echo -e "\\n[WARNING] [$(date +"%Y-%m-%d %H:%M:%S")] Invalid selection: $input. Please enter values between 1 and $count, or type 'all'."
                choose_and_set_project_id
                return
            fi
        done
    fi
}

# Remove existing Log sink
function remove_log_sink() {
    sink_name="$function_name-sink-logs-to-logzio"
    if gcloud logging sinks describe $sink_name --quiet &> /dev/null; then
        delete_code=$(gcloud logging sinks delete $sink_name --quiet || true)
        if [[ $? -ne 0 ]]; then
            echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] Failed to remove existing log sink: $sink_name."
        else 
            echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Log sink: $sink_name removed."
        fi
    else 
        echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Log sink: $sink_name not found."    
    fi
}

# Remove existing Pub/Sub topic
function remove_pubsub_topic(){
    topic_name="$function_name-pubsub-topic-logs-to-logzio"
    if gcloud pubsub topics describe $topic_name --quiet &> /dev/null; then
        delete_code=$(gcloud pubsub topics delete $topic_name --quiet || true)
        if [[ $? -ne 0 ]]; then
            echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] Failed to remove existing PubSub topic: $topic_name."
        else
            echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] PubSub topic: $topic_name removed."
        fi
    else
        echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] PubSub topic: $topic_name not found."
    fi
}

# Remove existing Cloud Function
function remove_cloud_function() {
    if gcloud functions describe $function_name --region=$gcp_region &> /dev/null; then
        delete_code=$(gcloud functions delete $function_name --region=$gcp_region --quiet || true)
        if [[ $? -ne 0 ]]; then
            echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] Failed to remove Cloud Function."
        else 
            echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Cloud Function: $function_name removed."
        fi
    else
        echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Cloud Function: $function_name not found."
    fi
}

# Cleanup existing resources
function cleanup_resources(){

    for project_id in "${selected_projects[@]}"
    do
        echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Cleanup existing resources for '$project_id'..."
        gcloud config set project $project_id

        if [[ $? -ne 0 ]]; then
            echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] Failed to set project $project_id."
            exit 1
        fi
        echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Setting up Logz.io integration resources in Project ID: '$project_id'..."
        
        # Call the functions to cleanup resources
        remove_log_sink $project_id
        remove_pubsub_topic $project_id
        remove_cloud_function $project_id

        echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Cleanup completed for Project ID: '$project_id'."
    done   
}


is_gcloud_install
gcloud_init_confs
get_arguments "$@"
populate_data_to_json
choose_and_set_project_id
cleanup_resources