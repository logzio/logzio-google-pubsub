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

### Pull integration
There are 2 options are available to pull the integration:

1. Clone repository
  - 
  ```shell
  Make sure you are connected to the relevant GCP project
  -
<details> Log in to your GCP account:
  
  ```shell
  gcloud auth login
  ``` 
  - Donwload and unzip the latest release of `logzio-google-pubsub`.
  - Navigate to the relevant project.
2. Run Google Cloud Shell configuration

  - [Click this link](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/logzio/logzio-google-pubsub
  ) to clone the solution's repo and use it in your Google Cloud Shell.
  :::note
  If a pop-up window appears, check the `Trust repo` box and press `Confirm`.
  :::

## Usage

1. Allow the `sh` file to execute code.

```shell
chmod +x run.sh
```

2. Run the code:

```
./run.sh --listener_url=<listener_url> --token=<token> --gcp_region=<region> --log_type=<type> --function_name=<function_name> --telemetry_list=<telemetry_list>
```

<b>When you run this script, you should choose the project ID/s where you need to run the integration, you can choose `all` to deploy resources on all projects</b>

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

# Uninstall

###  gcp_region - Region where user want to remove Logz.io integration resources.
###  function_name - Name of the Cloud Function. Default is 'logzioHandler'

To uninstall the resources, run the following command:

```shell
chmod +x uninstall.sh && ./uninstall.sh --gcp_region=<region> --function_name=<function_name>
```

## License

Licensed under the [Apache 2.0](http://apache.org/licenses/LICENSE-2.0.txt) License.

## Changelog
- **1.2.8**:
  - Allow fresh deployment to multiple projects, includes 'all' option.
  - Add `uninstall.sh` option to remove resources.
- **1.2.7**:
  - **Breaking change**
    - Upgrade Google Cloud function to v2
      - Add additional required permissions for the function
  - Add function resources cleanup
  - Additional function debugging logs
  - Refactor config steps to functions in run script
    - Create PubSub topic.
    - Create LogSink.
  - Update inclusion filter    
- **1.2.6**:
  - **Bug fix** for multiple resource types condition.
  - Upgrade GoLang runtime to v1.21
- **1.2.5**:
  - **Bug fix** for project numbers with more than 2 digits.
- **1.2.4**:
  - Support agent all_services as parameter of telemetry_list.
- **1.2.3**:
  - Add prefix to the function name
- **1.2.2**:
  - Rename param from `resource_list` to `telemetry_list`
- **1.2.1**:
  - Add function that user can choose project id where need to run integration
- **1.2.0**:
  - Replace location of the cloud function from cloud storage to local 
  - Replace trigger function from HTTP to pubsub trigger
- **1.1.0**:
  - Replace sink filter to google cloud resource type
- **1.0.0**:
  - Initial Release
