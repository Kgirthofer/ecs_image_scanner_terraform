import json
import logging
import boto3
import os
import time

from urllib2 import Request, urlopen, URLError, HTTPError
from base64 import b64decode


ecr = boto3.client('ecr')

# The base-64 encoded, encrypted key (CiphertextBlob) stored in the kmsEncryptedHookUrl environment variable
ENCRYPTED_HOOK_URL = os.environ['kmsEncryptedHookUrl']

# The Slack channel to send a message to stored in the slackChannel environment variable
SLACK_CHANNEL = os.environ['slackChannel']

ENVIRONMENT = os.environ['env']

HOOK_URL = "https://" + boto3.client('kms').decrypt(CiphertextBlob=b64decode(ENCRYPTED_HOOK_URL))['Plaintext'].decode('utf-8')

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.debug(event)
    imageTag = event['detail']['requestParameters']['imageTag']
    imageDigest = event['detail']['responseElements']['image']['imageId']['imageDigest']
    repositoryName = event['detail']['requestParameters']['repositoryName']
    logger.info("Scanning Image: %s:%s", repositoryName, imageTag)
    logger.info("Image Digest: %s", imageDigest)
    response = ecr.describe_image_scan_findings(
        repositoryName=repositoryName,
        imageId={
            'imageTag': imageTag
        }
    )

    while response['imageScanStatus']['status'] == 'IN_PROGRESS':

        time.sleep(10) 
        response = ecr.describe_image_scan_findings(
            repositoryName='string',
            imageId={
                'imageTag': 'string'
            }
        )

    try:
        criticalFindings = response['imageScanFindings']['findingSeverityCounts']['CRITICAL']
    except KeyError:
        criticalFindings = 0
    try:
        highFindings = response['imageScanFindings']['findingSeverityCounts']['HIGH']
    except KeyError:
        highFindings = 0
    try:
        mediumFindings = response['imageScanFindings']['findingSeverityCounts']['MEDIUM']
    except KeyError:
        mediumFindings = 0
    try:
        lowFindings = response['imageScanFindings']['findingSeverityCounts']['LOW']
    except KeyError:
        lowFindings = 0
    try:
        infoFindings = response['imageScanFindings']['findingSeverityCounts']['INFORMATIONAL']
    except KeyError:
        infoFindings = 0
    try:
        undefinedFindings = response['imageScanFindings']['findingSeverityCounts']['UNDEFINED']
    except KeyError:
        undefinedFindings = 0


    logger.info("CRITICAL: %d | HIGH: %d | MEDIUM: %d | LOW: %d | INFORMATIONAL: %d | UNDEFINED: %d", criticalFindings, highFindings, mediumFindings, lowFindings, infoFindings, undefinedFindings)

    if criticalFindings > 0:
        logger.info("Sending Critical Error")
        level = "danger"
        send_slack(ENVIRONMENT, repositoryName, imageTag, imageDigest, criticalFindings, highFindings, mediumFindings, lowFindings, infoFindings, undefinedFindings, level)
    elif highFindings > 0:
        logger.info("Sending High Error")
        level = "warning"
        send_slack(ENVIRONMENT, repositoryName, imageTag, imageDigest, criticalFindings, highFindings, mediumFindings, lowFindings, infoFindings, undefinedFindings, level)
    else:
        level = "good"
        if ENVIRONMENT == "prod":
            send_slack(ENVIRONMENT, repositoryName, imageTag, imageDigest, criticalFindings, highFindings, mediumFindings, lowFindings, infoFindings, undefinedFindings, level)
        else:
            logger.info("Skipping Slack notification because QA and All is good. Logging for audit trail")

def send_slack(ENVIRONMENT, repositoryName, imageTag, imageDigest, criticalFindings, highFindings, mediumFindings, lowFindings, infoFindings, undefinedFindings, level):
    logger.debug("in function")
    slack_message = {
        "channel": SLACK_CHANNEL,
        "username": "%s ECR Image Scanner" % (ENVIRONMENT),
        "text": "Alert on %s:%s - The following vulnerabilities were found" % (repositoryName, imageTag),
        "icon_emoji": ":ecr:",
        "attachments": [
        {
            "title": "Image Scan Findings",
            "title_link": "https://us-west-2.console.aws.amazon.com/ecr/repositories/%s/image/%s/scan-results?region=us-west-2" % (repositoryName, imageDigest),
            "author_name": "AWS ECR",
            "color": "%s" % (level),
            "text": "CRITICAL: %s\nHIGH: %s\nMEDIUM: %s\nLOW: %s\nINFORMATIONAL: %s\nUNDEFINED: %s" % (str(criticalFindings), str(highFindings), str(mediumFindings), str(lowFindings), str(infoFindings), str(undefinedFindings))

        }]
    }

    req = Request(HOOK_URL, json.dumps(slack_message))
    try:
        response = urlopen(req)
        logger.debug(response)
        response.read()
        logger.info("Message posted to %s", slack_message['channel'])
    except HTTPError as e:
        logger.error("Request failed: %d %s", e.code, e.reason)
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)
