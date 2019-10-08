#!/bin/bash

# Update these sections with details about your project
ACCOUNT_ID=XXXXXXXXXXXX
PROJECT_ID=core-api
PROJECT_NAME=CoreLambdaAPI
PROJECT_DESCRIPTION="Sample .NET Core API with AWS Lambda hosting"
# AWS CodeStar creates default role automatically when you navigate 
# to the Console and try to create a new project for the first time.
# You can use the default role or provide a custom one below.
CODESTAR_ROLE_ARN=arn:aws:iam::$ACCOUNT_ID:role/service-role/aws-codestar-service-role
# Default bucket name to store project template artifacts
BUCKET_NAME=$ACCOUNT_ID-codestar-templates

# Archive source code
pushd src; zip -r ../src.zip *; popd

# Create bucket, if needed
aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; 
if [[ $? -ne 0 ]]; then
  aws s3api create-bucket --bucket "$BUCKET_NAME"
fi

# Upload source code archive to S3
aws s3 cp src.zip s3://$BUCKET_NAME

# Upload toolchain template
aws s3 cp toolchain/toolchain.yml s3://$BUCKET_NAME

# Process default CodeStar template
sed -e "s|\${PROJECT_ID}|$PROJECT_ID|" \
    -e "s|\${PROJECT_NAME}|$PROJECT_NAME|" \
    -e "s|\${PROJECT_DESCRIPTION}|$PROJECT_DESCRIPTION|" \
    -e "s|\${CODESTAR_ROLE_ARN}|$CODESTAR_ROLE_ARN|" \
    -e "s|\${BUCKET_NAME}|$BUCKET_NAME|" \
    codestar_template.json > codestar_deploy.json

# Create CodeStar project based on toolchain and source code
aws codestar create-project --cli-input-json file://codestar_deploy.json