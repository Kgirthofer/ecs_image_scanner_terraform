# ECR Image Scanning with Terraform 

a lil thing that scans your ECR images and then notifies slack if you have vulnerabilities. 

## Usage

Download the most recent version of boto3 - at the time of creating this the most recent version is 1.10.16.
You need to do this because boto3 on lambda doesn't have ECR's new scanning capabilities. 
```console
LIB_DIR=~/boto3/python
mkdir -p $LIB_DIR
pip3 install boto3 -t $LIB_DIR
cd boto3/
aws lambda publish-layer-version --layer-name boto3-1.10.16 --zip-file fileb:///tmp/boto3-mylayer.zip
```

Create a new KMS key 
```console
createKey=`aws kms create-key --tags TagKey=Purpose,TagValue=Slack --description "Used for Lambda to encrypt and decrypt Slack URL"`
keyId=`echo ${createKey} | jq -r '.KeyMetadata.KeyId'`
keyArn=`echo ${createKey} | jq -r '.KeyMetadata.Arn'`
aws kms create-alias --alias-name alias/LambdaSlack --target-key-id ${keyId}

```

Use that key to Encrypt your Slack Incoming Webhook URL - this will give you a big blurb of text - copy that into the variables.tf file as the "encrypted_hook_url"
```console
aws kms encrypt --key-id ${keyId} --plaintext 'hooks.slack.com/services/SUPER/SECRET/HIDDENURL' --output text --query CiphertextBlob
```
Follow this to figure out how to set up an incoming webhook if you don't already 
https://api.slack.com/messaging/webhooks

finally zip up the python file, after making any adjustments that you'd like, and run terraform apply
```console
zip lambda_function_payload.zip imageScanner.py
terraform init
terraform plan 
terraform apply
```

Now every time you push a new image to a repo, if you have "Scan on Push" enabled, this lambda will trigger, scan the new image, and alert slack if needed. 


## Variables

- `vpc_id` - ID of VPC meant to house cluster
- `environment` - Environment you're going to launch into. I have it separated into QA and PROD so that QA only alerts on HIGH and CRITICAL vulnerabilities.
- `profile` - I've included profile usage, if that's your thing.
- `region` 
- `function_name` - leave this default
- `handler` - leave this default
- `runtime` - Running on py2.7 because I don't have time to figure out the urllib for python3.
- `boto3_layer_name` - what ever you named your boto3 layer name in step 1
- `boto3_layer_version` - and the version of the layer, this is given to you when you push up the layer. 
- `encrypted_hook_url` - the big blurb of text you'll receive in step 3, encrypting the URL

## Outputs

