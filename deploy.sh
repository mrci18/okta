#!/bin/bash

### Functions ###
function deploy_kms(){
    echo -e "\n\nDeploying ${1}..."
    aws cloudformation deploy \
        --no-fail-on-empty-changeset \
        --template-file ${2} \
        --stack-name ${1} \
        --parameter-overrides \
            Team=${team} User=${username}
}

function set_secure_ssm(){
    kmsID=$(aws cloudformation describe-stacks --stack-name ${3} --query "Stacks[].Outputs[].OutputValue[]" --output text | awk '{print $2}')
    echo -e "\nSetting SSM for ${1}"

    aws ssm put-parameter --cli-input-json '{"Type": "SecureString", "KeyId": "'"${kmsID}"'", "Name": "'${1}'", "Value": "'"${2}"'"}' --overwrite
}

function deploy_pipeline_bucket(){
    aws cloudformation deploy \
        --no-fail-on-empty-changeset \
        --template-file ./infra/pipeline/bucket/PipelineBucket.yaml \
        --stack-name SecurityDeploymentBucket
}

function deploy_pipeline_role(){
    echo -e "\n\nDeploying CodePipeline Role..."
    aws cloudformation deploy \
        --no-fail-on-empty-changeset \
        --template-file infra/pipeline/iam/CodePipelineRole.yaml \
        --stack-name CodePipelineRoleStack \
        --parameter-overrides \
            Service=${service} \
            OktaUserName=${oktaUsername}
        --capabilities CAPABILITY_NAMED_IAM
}

function deploy_regular_cft(){
    echo -e "\n\nDeploying ${1}..."
    aws cloudformation deploy \
        --no-fail-on-empty-changeset \
        --template-file ${2} \
        --stack-name ${1} \
        --capabilities CAPABILITY_NAMED_IAM
}

function deploy_pipeline(){
    echo -e "\n\nDeploying Pipeline..."
    aws cloudformation deploy \
        --no-fail-on-empty-changeset \
        --template-file infra/pipeline/Pipeline.yaml \
        --stack-name ${service}Pipeline \
        --parameter-overrides \
            Service=${service} \
            Team=${team} \
            BranchName=${branch} \
            RepositoryName=${repo} \
            GitHubOwner=${gitOwner} \
            GitHubSecret=${gitPassword} \
            GitHubOAuthToken=${oAuth} \
        --capabilities CAPABILITY_NAMED_IAM
    echo -e "\nCheck Codepipeline to view the status of deployment..."
    echo -e "Wait until script is fully finished executing..."
}

### Inputs ###
# read -p "AWS username to administer the KMS key (e.g. bob@matson.com): " username

## Init config
service="Okta"
oktaUsername="okta-master"
message="INFO: You are about to input sensitive data; your input will not be echo'd back to the terminal"
team="Security"

## Slack config
# echo -e "\n${message}"
# read -sp "The webhook URL from slack for errors: " error_webhook

# echo -e "\n\n${message}"
# read -sp "The webhook URL from slack for security deployment channel: " deployment_webhook

# ## Okta inputs
# echo -e "\n${message}"
# read -sp "The URL for Okta XML: " okta_xml_url

## For pipeline config
branch="master"
gitOwner="mrci18"
repo="okta"

echo -e "\n${message}"
read -sp "GitHub OAuth Token (Reference the doc link above if you need help): " oAuth

echo -e "\n\n${message}"
read -sp "Github password (i.e The GitHub account password that created the OAuthToken above): " gitPassword

### Main ###
# deploy_kms AWSErrorKeyStack infra/kms/security_errors_key.yaml
# deploy_kms SecurityDeploymentKeyStack infra/kms/security_deployment_key.yaml
# # set_secure_ssm SECURITY_ERRORS_SLACK ${error_webhook} AWSErrorKeyStack
# set_secure_ssm SECURITY_DEPLOYMENT_SLACK ${deployment_webhook} SecurityDeploymentKeyStack
# set_secure_ssm OktaMetadataURL ${okta_xml_url} SecurityDeploymentKeyStack

# # #Add Monitor CFT
# # #deploy_regular_cft MonitorDeployerRoleStack monitoring/MonitorDeployerRole.yaml

# deploy_pipeline_bucket
deploy_regular_cft ${service}PipelineRoles infra/pipeline/iam/CodePipelineRole.yaml
deploy_pipeline

# Put in another script
# Deploy Service Role
# function deploy_service_deployer_role(){
#     echo -e "\n\nDeploying ${service} Deployer Role..."
#     aws cloudformation deploy \
#         --no-fail-on-empty-changeset \
#         --template-file infra/pipeline/iam/OktaDeployerRole.yaml \
#         --stack-name ${service}DeployerRole \
#         --parameter-overrides \
#             Service=${service} \
#             LService=${lservice} \
#         --capabilities CAPABILITY_NAMED_IAM
# }