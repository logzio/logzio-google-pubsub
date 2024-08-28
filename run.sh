#!/bin/bash

# Declare default type
log_type="gcp-pubsub"
function_name="logzio_handler"
project_id=""
telemetry_list="all_services"
gcp_region=""
selected_projects=()

# Prints usage
# Output:
#   Help usage
function show_help () {
    echo -e "Usage: ./run.sh --listener_url=<listener_url> --token=<token> --gcp_region=<region> --function_name=<function_name> --log_type=<log_type> --telemetry_list=<telemetry_list> "
    echo -e " --listener_url=<listener_url>       Logz.io Listener URL (You can check it here https://docs.logz.io/user-guide/accounts/account-region.html)"
    echo -e " --token=<token>                     Logz.io token of the account you want to ship to."
    echo -e " --gcp_region=<gcp_region>           Region where you want to upload Cloud Funtion."
    echo -e " --function_name=<function_name>     Function name will be using as Cloud Function name and prefix for services."
    echo -e " --telemetry_list=<telemetry_list>   Will send logs that match the Google resource type. Array of strings splitted by comma. Detailed list you can find https://cloud.google.com/logging/docs/api/v2/resource-list"
    echo -e " --log_type=<log_type>               Log type. Help classify logs into different classifications"
    echo -e " --help                              Show usage"
}

# Gets arguments
# Input:
#   Client's arguments ($@)
# Output:
#   listener_url - Logz.io Listener URL
#   token - Logz.io token of the account user want to ship to.
#   gcp_region - Region where user want to upload Cloud Funtion.
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
            --gcp_region=*)
                gcp_region=$(echo "$1" | cut -d "=" -f2)
                if [[ "$gcp_region" = "" ]]; then
                    echo -e "\033[0;31mrun.sh (1): no Google Cloud Region specified!\033[0;37m"
                    exit 1
                fi
                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] gcp_region = $gcp_region" 
                ;;
             --log_type=*)
                log_type=$(echo "$1" | cut -d "=" -f2)
                if [[ "$log_type" = "" ]]; then
                    echo -e "\033[0;31mrun.sh (1): Type will be assign gcp-pubsub\033[0;37m"
                    #Define default
                    log_type="gcp-pubsub"
                fi
                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] log_type = $log_type" 
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
            --telemetry_list=*)
                telemetry_list=$(echo "$1" | cut -d "=" -f2)
                if [[ "$telemetry_list" = "" ]]; then
                    echo -e "\033[0;31mrun.sh (1): No resource types assigned to sink\033[0;37m"
                    #Define default
                fi
                echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] telemetry_list = $telemetry_list" 
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
        echo -e "\033[0;31mrun.sh (1): Logz.io Listener URL is missing please rerun the script with the relevant parameters\033[0;37m"
    fi
    if [[ -z "$token" ]]; then
        is_error=true
        echo -e "\033[0;31mrun.sh (1): Logz.io Token is missing please rerun the script with the relevant parameters\033[0;37m"
    fi
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

# Populate filter for service names
function populate_filter_for_service_name(){
    if [[ ! -z "$telemetry_list" ]]; then
	filter=" AND"
	array_filter_names=(${telemetry_list//,/ })

	last_element=${#array_filter_names[@]}
	current=0
	for name in "${array_filter_names[@]}"
    do
	    current=$((current + 1))
	    if [ $current -eq $last_element ]; then
	        filter+=" resource.type=${name}"
        else
	        filter+=" resource.type=${name} OR"
	    fi
    # or do whatever with individual element of the array
    done
	telemetry_list="${filter}"
    fi
	
    if [[ $filter == *"all_services"* ]]; then
            telemetry_list=""
    fi
	echo "$telemetry_list"
}

# Populate data to json
function populate_data_to_json (){
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Populating data to json ..."

    contents="$(jq --arg token "${token}" '.substitutions._LOGZIO_TOKEN = $token' config.json)"
    echo "${contents}" > config.json
    contents="$(jq  --arg type_of_log "${log_type}" '.substitutions._TYPE_NAME = $type_of_log' config.json)"
    echo "${contents}" > config.json
    contents="$(jq --arg gcp_region "${gcp_region}" '.substitutions._REGION = $gcp_region' config.json)"
    echo "${contents}" > config.json
    contents="$(jq --arg listener_url "${listener_url}" '.substitutions._LOGZIO_LISTENER = $listener_url' config.json)"
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
    if [[ ! -z "$telemetry_list" ]]; then
        contents="$(jq --arg telemetry_list "${telemetry_list}" '.substitutions._FILTER_LOG = $telemetry_list' config.json)"
        echo "${contents}" > config.json
    else
        contents="$(jq --arg telemetry_list "${telemetry_list}" '.substitutions._FILTER_LOG = ""' config.json)"
        echo "${contents}" > config.json
    fi
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
            # Call the functions to cleanup resources
        remove_log_sink $project_id
        remove_pubsub_topic $project_id
        remove_cloud_function $project_id

        echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Cleanup completed for Project ID: '$project_id'."
    done   
}

# Add IAM policy to Log sink
function _add_log_sink_iam_policy(){
    topic_name="$function_name-pubsub-topic-logs-to-logzio"
    sink_name="$function_name-sink-logs-to-logzio"
    cmd_add_iam_log_sink="gcloud logging sinks describe $sink_name |\nwhile read -r line\ndo\n  stringarray=($line)\n\n  if [ ${stringarray[0]} == 'writerIdentity:' ]\n  then\n    identity=\"${stringarray[1]}\"\n    gcloud pubsub topics add-iam-policy-binding $topic_name --member \"${identity}\" --role roles/pubsub.publisher \n  fi\ndone\n"
    gcloud logging sinks describe $sink_name | while read -r line
    do
    stringarray=($line)
    if [ ${stringarray[0]} == 'writerIdentity:' ]
    then
    identity=${stringarray[1]}   
    gcloud pubsub topics add-iam-policy-binding $topic_name --member ${identity} --role roles/pubsub.publisher
    fi
    done

    echo "$cmd_add_iam_log_sink"
    
    if [[ $? -ne 0 ]]; then
        echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] Failed to add IAM policy to Log sink: $sink_name."
        exit 1
    else 
        echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] IAM policy addition to Log sink: $sink_name is finished."    
    fi
}

# Create Log sink
function create_log_sink(){
    topic_name="$function_name-pubsub-topic-logs-to-logzio"
    sink_name="$function_name-sink-logs-to-logzio"
    cmd_create_log_sink="gcloud logging sinks create $sink_name pubsub.googleapis.com/projects/$project_id/topics/$topic_name --log-filter=\"NOT (resource.type=\"cloud_function\" resource.labels.function_name=~\"logzio_.\")$telemetry_list\""
    echo "$cmd_create_log_sink"
    gcloud logging sinks create $sink_name pubsub.googleapis.com/projects/$project_id/topics/$topic_name --log-filter="NOT (resource.type=\"cloud_function\" resource.labels.function_name=~\"logzio_.\")$telemetry_list"
    if [[ $? -ne 0 ]]; then
        echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] Failed to create Log sink: $sink_name."
        exit 1
    else
        echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Log sink: $sink_name created."
        _add_log_sink_iam_policy
    fi
}

# Create PubSub topic
function create_pubsub_topic(){
    topic_name="$function_name-pubsub-topic-logs-to-logzio"
    cmd_create_pubsub_topic="gcloud pubsub topics create $topic_name"
    echo "$cmd_create_pubsub_topic"
    gcloud pubsub topics create $topic_name    
    if [[ $? -ne 0 ]]; then
        echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] Failed to create PubSub topic: $topic_name."
        exit 1
    else 
        echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] PubSub topic: $topic_name created."    
    fi
}

# Run Cloud Build
function run_cloud_build(){
    
    echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Initialize Cloud Build ..."
    # Take project ID and project Number
    project_number="$(gcloud projects list \
    --filter="$(gcloud config get-value project)" \
    --format="value(PROJECT_NUMBER)")"
 
    # Give permission for Cloud Build to assign proper roles
    cmd_enable_cloudresourcemanager="$(gcloud services enable cloudresourcemanager.googleapis.com)"
    cmd_enable_cloudbuild="$(gcloud services enable cloudbuild.googleapis.com)"
    cmd_enable_cloudfunction="$(gcloud services enable cloudfunctions.googleapis.com)"
    cmd_enable_run_api="$(gcloud services enable run.googleapis.com)"
    cmd_enable_eventarc="$(gcloud services enable eventarc.googleapis.com)"

    cmd_add_policy="$(gcloud projects add-iam-policy-binding $project_id --member serviceAccount:$project_number@cloudbuild.gserviceaccount.com --role roles/resourcemanager.projectIamAdmin)"
    cmd_enable_policy_function="$(gcloud iam service-accounts add-iam-policy-binding $project_id@appspot.gserviceaccount.com --member serviceAccount:$project_number@cloudbuild.gserviceaccount.com --role roles/iam.serviceAccountUser)"

    #Get Access Token for upload
    access_token="$(gcloud config config-helper --format='value(credential.access_token)')"
    # Run project
    cmd_create_cloud_build="$(curl -X POST -T config.json -H "Authorization: Bearer $access_token" https://cloudbuild.googleapis.com/v1/projects/$project_id/builds)"

    # Create Function with using local files
    if [[ "$function_name" =~ ^logzio_* ]];
    then
        function_name_suffix="${function_name}"
    else
        function_name_suffix="logzio_${function_name}"
    fi

    topic_name="$function_name-pubsub-topic-logs-to-logzio"

    gcloud functions deploy $function_name --gen2 --region=$gcp_region  --retry --trigger-topic=$topic_name --entry-point=LogzioHandler --runtime=go121  --source=./cloud_function_go  --no-allow-unauthenticated --set-env-vars=token=$token --set-env-vars=type=$log_type --set-env-vars=listener=$listener_url
    
    echo "$cmd_create_cloud_build"

    if [[ $? -ne 0 ]]; then
        echo -e "[ERROR] [$(date +"%Y-%m-%d %H:%M:%S")] Failed to create Cloud Function."
        exit 1
    else 
        echo -e "[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] Cloud Function: $function_name created."    
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
    read -p "Please fill in the project index numbers of the projects where you would like the integration to be deployed, separated by spaces (or type 'all' to select all projects): " -a mainmenuinput

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

# Deploy resources to the selected projects
function deploy_resources_to_projects() {
    for project_id in "${selected_projects[@]}"
    do
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

        # Call the functions to create resources
        create_pubsub_topic $project_id
        create_log_sink $project_id
        run_cloud_build $project_id
    done
}

is_gcloud_install
gcloud_init_confs
get_arguments "$@"
populate_filter_for_service_name
populate_data_to_json
choose_and_set_project_id
deploy_resources_to_projects
