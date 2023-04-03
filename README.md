# Pub/Sub to Logz.io

Google Cloud Platform (GCP) Logging collects logs from your cloud services. You can use Google Cloud Pub/Sub to forward your logs from GP sinks to Logz.io.

## Prerequisites

-   Installed [gcloud CLI](https://cloud.google.com/sdk/docs/install)
-   Active GCP account
-   Installed [jq](https://stedolan.github.io/jq/download/)

## Resources

-   Cloud Build
-   Pub/Sub
-   Cloud Function
-   Log Sink

## Prerequisites

Make sure you are connected to the relevant GCP project

<details>1. Log in to your GCP account:

```shell
gcloud auth login
```

2. Navigate to the relevant project.

3. Set the `project id` for the project that you want to send logs from:

```shell
gcloud config set project <PROJECT_ID>
```

Replace `<PROJECT_ID>` with the relevant project Id.</details>

## Usage

1. Donwload and unzip the latest release of `logzio-google-pubsub`.

2. Navigate to the `builder` folder.

3. Allow the `sh` file to execute code.

```shell
chmod +x run.sh
```

4. Run the code:

```
./run.sh --listener_url=<listener_url> --token=<token> --gcp_region=<region> --log_type=<type> --function_name=<function_name> --telemetry_list=<telemetry_list>
```

<b>When you run this script, you should choose the project ID where you need to run the integration.</b>

Replace the variables as per the table below:

| Parameter      | Description                                                                                                                                                                                               |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| listener_url   | Use the listener URL specific to the region of your Logz.io account. You can look it up [here](https://docs.logz.io/user-guide/accounts/account-region.html).                                             |
| token          | The logs' shipping token of the account you want to ship to.                                                                                                                                              |
| gcp_region     | Region where you want to upload Cloud Function. \*`Requires for Deploy to Cloud option for platform`.                                                                                                     |
| log_type       | Log type. Help classify logs into different classifications. (Default:`gcp-pubsub`)                                                                                                                       |
| function_name  | Function name will be using as Google Cloud Function name. (Default:`logzioHandler`)                                                                                                                      |
| telemetry_list | **_Optional_** Will send logs that match the Google resource type. Detailed list you can find [here](https://cloud.google.com/logging/docs/api/v2/resource-list) (ex: `pubsub_topic,pubsub_subscription`) |

## Check Logz.io for your logs

Give your logs some time to get from your system to ours, and then open [Kibana](https://app.logz.io/#/dashboard/kibana).

## License

Licensed under the [Apache 2.0](http://apache.org/licenses/LICENSE-2.0.txt) License.

## Changelog

-   **1.2.4**

    Support agent all_services as parameter of telemetry_list

-   **1.2.3**

    Add prefix to the function name

-   **1.2.2**

    Rename param from `resource_list` to `telemetry_list`

-   **1.2.1**

    Add function that user can choose project id where need to run integration

-   **1.2.0**

    Replace location of the cloud function from cloud storage to local
    Replace trigger function from HTTP to pubsub trigger

-   **1.1.0**

    Replace sink filter to google cloud resource type

-   **1.0.0**

    Initial Release
