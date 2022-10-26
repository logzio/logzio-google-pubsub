#!/bin/bash

TOKEN=$2
LISTENER_URL=$1
REGION=$3
TYPE_NAME=$3


# populate arguments to the json file

echo -n "" > config.json

filename='config_txt.txt'
while IFS= read -r line; do

  stringarray=($line)
        if [ ${stringarray[0]} == "\"_LOGZIO_TOKEN\":" ]
        then

		  line='"_LOGZIO_TOKEN": "'$TOKEN'"',
        fi
        if [ ${stringarray[0]} == "\"_LOGZIO_LISTENER:\"" ]
        then

		  line='"_LOGZIO_LISTENER": "'$LISTENER_URL'"',
        fi
		if [ ${stringarray[0]} == "\"_REGION\":" ]
        then

		  line='"_REGION": "'$REGION'"',

        fi
		if [ ${stringarray[0]} == "\"_TYPE_NAME\":" ]
        then

		  line='"_TYPE_NAME": "'$TYPE_NAME'"'

        fi
		echo "$line" >> config.json
done < $filename

# Take project ID and project Number
project_number="$(gcloud projects list \
--filter="$(gcloud config get-value project)" \
--format="value(PROJECT_NUMBER)")"
project_id="$(gcloud config get-value project)"

# Give permission for Cloud Build to assign proper roles
cmd_add_policy="$(gcloud services enable cloudresourcemanager.googleapis.com)"
cmd_add_policy="$(gcloud services enable cloudbuild.googleapis.com)"
cmd_add_policy="$(gcloud projects add-iam-policy-binding $project_id --member serviceAccount:$project_number@cloudbuild.gserviceaccount.com --role roles/resourcemanager.projectIamAdmin)"

# Run project
cmd_create_cloud_build="$(curl -X POST -T config.json -H "Authorization: Bearer $(gcloud config config-helper --format='value(credential.access_token)')" https://cloudbuild.googleapis.com/v1/projects/$project_id/builds)"

echo "$cmd_create_cloud_build"


