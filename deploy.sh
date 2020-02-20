#!/bin/bash
read -p "Enter the URL of the okta application XML: " oktaMetadataURL
wget -O metadata.xml ${oktaMetadataURL} 
cat metadata.xml | tr -d '\n' | sed -e 's/"/\"/g' > out.xml
aws cloudformation deploy --no-fail-on-empty-changeset --template-file ./provider.yaml --stack-name OktaProvider --parameter-overrides MetadataDocument="$(cat out.xml)" SamlProviderName=okta --capabilities CAPABILITY_NAMED_IAM