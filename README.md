# Pub/Sub to Logz.io

Google Cloud Platform (GCP) Logging collects logs from your cloud services. You can use Google Cloud Pub/Sub to forward your logs from Logging->Sink to Logz.io.

## Prerequisites

-   Install gcloud cli and login to gcloud
-   Install [jq](https://stedolan.github.io/jq/download/)
-   Download Latest Release

## Resources

-   Cloud Build
-   Pubsub
-   Cloudfunction
-   Log Sink

## Usage

1. Please make sure you are logged in to the relevant project
   `gcloud auth login`
   And choose relevant account to login.

2. Set default project id, from what project you want to send logs.
   `gcloud config set project <PROJECT_ID>`

And need to have assigned to the project, Billing Account.

3. Donwload and Unzip Latest Release

4. Go to, via terminal to unzip `builder` folder

```
cd builder
```

5. Give permission to sh file to execute a code

```
chmod +x run.sh
```

6. Run the code with the following variables

```
./run.sh --listener_url=<listener_url> --token=<token> --region=<region> --type=<type>
```

| Parameter    | Description                                                                                                                                                   |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| listener_url | Use the listener URL specific to the region of your Logz.io account. You can look it up [here](https://docs.logz.io/user-guide/accounts/account-region.html). |
| type         | Log type. Help classify logs into different classifications. (Default:`gcp-pubsub`)                                                                           |
| token        | The token of the account you want to ship to.                                                                                                                 |
| region       | Region where you want to upload Cloud Function. \*`Requires for Deploy to Cloud option for platform`.                                                         |

## Check Logz.io for your logs

Give your logs some time to get from your system to ours,
and then open [Kibana](https://app.logz.io/#/dashboard/kibana).

## License

Licensed under the [Apache 2.0](http://apache.org/licenses/LICENSE-2.0.txt) License.

## Update log

**1.0.0**

-   Initial Release
