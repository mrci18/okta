# Slack
AThis slack webhook allows us to get notifications for our deployments happening 
- Create slack app
- Under that slack app, create a new webhook for #security-deployments channel

# Okta
This Okta URL is needed to know which Okta source to link our Identity Provider on AWS

- Log in to Okta(must be Okta application admin) in classic UI
- Click through Applications -> Amazon Web Services -> Sign On

- Under  Settings > SIGN ON METHODS > SAML 2.0
    - Right click `Identity Provider metadata`
    - Copy link address


# deploy.sh
This bash script is a reference point and prefered way to provision AWS resources for this repo
- Provisioned
    - [KMS key](#KMS)
    - [SSM secret parameters](#ssm-parameters)
    - [s3 bucket](#s3)
    - [IAM roles and policy](#pipeline-roles-and-policy)
    - [codepipeline and codebuild projects](#Pipeline)

- Inputs
The inputs will have a short description when prompted

- How to run
```sh
bash deploy.sh
```

# KMS
- Change arn of key in deployment_status.yaml when finally provisioning KMS key

This KMS key will be used to encrypt
- [Okta Metadata URL](#Okta)
- [Slack webhook URL](#Slack) 

The KMS key is deployed before everything because it is needed to encrypt SSM parameters. At the time of writing, SSM secret params are not supported by Cloudformation

# SSM Parameters
These SSM parameters are the easiest way to encrypt sensitive values reference in Codebuild project
Referen
- [Okta Metadata URL](#Okta)
    - Referenced by each codebuild project because it is needed to set the correct Okta source as the Identity Provider on AWS
- [Slack webhook URL](#Slack) 
    - Referenced by monitoring lambda
# S3
This s3 bucket will be used by codepipeline to store artifacts, (source artifacts used by codebuild to create build)
We want to use this as central codepipeline artifact store for security deployments. Each project will be represented as an object based on the codepipeline name.

# Pipeline roles and policy
Codepipeline role
- Basic rights needed to operate codepipeline
Codebuild role
- Permission to create resources with code build
    - IAM user, roles, policy, SAML
    - Cloudformation 
    - Assume deployer roles (ref below)in other AWS accounts

# Roles for non pipeline account
OktaDeployerRole.yaml must be provisioned after the pipeline has been provisioned because it references the specific codebuild role ARN that is build
- Provisioned in another AWS account
- Permission to create resources with code build
    - IAM roles, policy, SAML
    - Cloudformation 

# Pipeline
The pipeline stage has 4 stages.
- Source
    - This pipeline is hooked to the master branch of an okta repo

- Build
    - This step has all non production AWS accounts
    - Each account will have a reference to the okta-base.yaml
        - Sets Okta as the IdP in AWS account
        - Provisions 6 base IAM roles and policies
    - The pipeline account will reference okta-user.yaml
        - Creates IAM user
            - Needed to provision access/secret key for Okta 
    - Non pipeline accounts will reference Okta-Idp-cross-account-role.yaml
        - Allows okta to look at what roles can be assumed by Okta
    - Create additional IAM roles per account in a separate CFT if needed
- Approve
    - Manual approval need to get to production builds
- Production Builds
    - Similar build to non pipeline accounts are applied here minus custom CFTs 
        - okta-base.yaml
        - Okta-Idp-cross-account-role.yaml



