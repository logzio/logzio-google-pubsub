# Pub/Sub to Logz.io

Google Cloud Platform (GCP) Logging collects logs from your cloud services. You can use Google Cloud Pub/Sub to forward your logs from GP sinks to Logz.io.

## Prerequisites

-   Installed [gcloud CLI](https://cloud.google.com/sdk/docs/install) installed
-   Active GCP account
-   Installed [jq](https://stedolan.github.io/jq/download/)

## Resources

-   Cloud Build
-   Pub/Sub
-   Cloud Function
-   Log Sink

## Usage

1. Log in to your GCP account:

```shell
gcloud auth login
```

2. Navigate to the relevant project.


3. Set the `project id` for the project that you want to send logs from:

```shell
gcloud config set project <PROJECT_ID>
```

Replace `<PROJECT_ID>` with the relevant project Id.

4. Assign a Billing Account to the selected project. 

5. Donwload and unzip the latest release of `logzio-google-pubsub`.

6. Navigate to the `builder` folder.

7. Allow the `sh` file to execute code.

```shell
chmod +x run.sh
```

9. Run the code:

```
./run.sh --listener_url=<listener_url> --token=<token> --region=<region> --type=<type>
```

Replace the variables as per the table below:


| Parameter    | Description                                                                                                                                                   |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| listener_url | Use the listener URL specific to the region of your Logz.io account. You can look it up [here](https://docs.logz.io/user-guide/accounts/account-region.html). |
| type         | Log type. Help classify logs into different classifications. (Default:`gcp-pubsub`)                                                                           |
| token        | The token of the account you want to ship to.                                                                                                                 |
| region       | Region where you want to upload Cloud Function. \*`Requires for Deploy to Cloud option for platform`.                                                         |

## Check Logz.io for your logs

Give your logs some time to get from your system to ours, and then open [Kibana](https://app.logz.io/#/dashboard/kibana).

## License

Licensed under the [Apache 2.0](http://apache.org/licenses/LICENSE-2.0.txt) License.

## Update log

**1.0.0**

-   Initial Release
