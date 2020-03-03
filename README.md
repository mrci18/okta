# Slack
- Create slack app and webhook for deployment status channel

# deploy.sh
## This bash script will be the source and should dictate the deploy flow the first time this repo is provisioned on the pipeline account
- Provisions 
    - [KMS key](#KMS)
    - [SSM secret parameters](#SSMParameters)
    - [s3 bucket](#s3)
    - [IAM roles and policy](#Pipelinerolesandpolicy)
    - [codepipeline and codebuild projects](#Pipeline)

# KMS
- Change arn of key in deployment_status.yaml when finally provisioning KMS key
The deployment KMS key is deployed before everything because it is needed to encrypt SSM values. At the time of writing, SSM secret params are not supported by Cloudformation

This KMS key will be used to encrypt
    - Okta Metadata URL
    - Slack webhook URL which is referenced in the deployment status lambda

The key error KMS key should be deployed per account with an SSM secret of a slack webhook URL that has a lambda. With this we will be able to plug slack as an error notification method for our lambdas

# SSM Parameters

# S3
This s3 bucket will be used by codepipeline to store source artifacts, (source artifacts used by codebuild to create build)
We want to use this as central codepipeline artifact store for security deployments. Each project will be represented as an object based on the codepipeline name.

# Pipeline roles and policy
Codepipeline role
    - Basic rights needed to operate codepipeline
Codebuild role
    - Permission to create resources with code build
        - IAM user, roles, policy, SAML
        - Cloudformation 
        - Assume deployer roles in other AWS accounts
Deployer Role
    - Provisioned in another AWS account
    - Permission to create resources with code build
        - IAM roles, policy, SAML
        - Cloudformation 

# Pipeline

# okta
IAM CFT templates for Okta 

# Account B
- CFT to set up IdP
- DeployerRole


# Need to figure out why builds are running twice

