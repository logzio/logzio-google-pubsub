# Pub/Sub to Logz.io

Google Cloud Platform (GCP) Logging collects logs from your cloud services. You can use Google Cloud Pub/Sub to forward your logs from Logging->Sink to Logz.io.

## Prerequisites

-   Install gcloud and login to gcloud
-   clone repository to your computer

## Resources

-   Cloud Build
-   Pubsub
-   Cloudfunction
-   Log Sink

## Usage

1. Before start a proccess please be sure that is you logged in and you setup relevant project.
   `gcloud auth login`
   And choose relevant account to login.

2. Set default project id, from what project you want to send logs.
   `gcloud config set project <PROJECT_ID>`

And Need to have assigned to the project, Billing Account.

3. Clone repository to the folder

```
 git clone  repo_name  builder
```

4. Go to the folder `builder`

```
cd builder
```

5. Give permission to sh file to execute a code

```
chmod +x run.sh
```

6. Run a code with variables

```
./run.sh LISTENER TOKEN REGION TYPE_OF_LOG
```

| Parameter                         | Description                                                                                                                             |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| LISTENER                          | Name of the Lambda function that will be created. This name will also be used to identify the Lambda function in the Logz.io dashboard. |
| TYPE_OF_LOG                       | Lambda function description.                                                                                                            |
| TOKEN                             | Your Logz.io logs shipping token.                                                                                                       |
| Schedule Rate (Default: 1 minute) | Range in a minutes to run a Lambda function (using cloudBridge event).                                                                  |
| REGION                            | Your AWS access key ID. \*`Requires for Deploy to Cloud option for platform`.                                                           |

## Check Logz.io for your logs

Spin up your Docker containers if you haven’t done so already.  
Give your logs some time to get from your system to ours,
and then open [Kibana](https://app.logz.io/#/dashboard/kibana).

## License

Licensed under the [Apache 2.0](http://apache.org/licenses/LICENSE-2.0.txt) License.
