# [service-name] (serverless reference project template)

### Introduction

### Setup Dynamo DB on local
1. Change directory to *./serverless* project

        $ cd serverless

2. Install DynamoDB Local

        $ sls dynamodb install

 This command should be executed only once for 
 installing Dynamo db locally.

 Once this command this executed, *.dynamodb* folder will be created where the local installation will be stored.

3. To launch the project

        $ sls offline start --migrate

After starting DynamoDB local, migrate option will help to create DynamoDB tables from your Serverless configuration(table names provided in resources section of serverless.yml).

For more detail on configuring Dynamo db locally refer: 

[serverless-dynamodb-local](https://www.npmjs.com/package/serverless-dynamodb-local)

### Running unit test

##### Unit test can be executed either from ./serverless/ project directory or from specific ./api-operations/{project} directory. Both the appraoches are listed below:

1. From serverless/ project directory

        $ cd serverless
        $ npm run unit-test

2. From specific api-operations/{project}

        $ cd api-operations/{project}
        $ npm test

Note: Unit test report can be found within projects src/unit-test folder

### Running code-coverage from ./serverless/ project directory
    $ npm run code-coverage

Note: Code coverage report can be found within ./serverless/ projects *coverage* folder

### Launch project, run component test and from ./serverless/ project directory
    $ npm run component-test

This will first launch the project using sls offline and then execute the component test

Note: Unit test report can be found within projects src/unit-test folder

### All in one command
#### Run unit test, code-coverage, launch project and execute component test from ./serverless/ project directory
    $ npm test

This will run unit test, launch the project using sls offline and then execute the component test

### Deploy lambda using serverless commands

1. Below aws credential fields of your AWS account should be set as environment variables

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION

2. To get the debug output of deployment steps performed by serverless then you can ON the debug mode either by setting it explicity on command prompt or by setting it as environment variable

        $ set SLS_DEBUG=*

3. Deploy

        $ sls deploy

- This will deploy the lambda in your provided AWS account
- It will also create an alias with the name same as stage(If stage is not provided using --stage option then default stage is assumed from the serverless.yml provider's section).
For more details on alias usage, refer [serverless-aws-alias](https://www.npmjs.com/package/serverless-aws-alias)
- If you want to create alias with different name then you have to provide the *--alias* parameter

### Remove lambda and its associated infrastructure

Before removing the lambda you need to first remove its alias

        $ sls alias remove --alias=dev

Now you can remove the actual lambda

        $ sls remove

Note: Please check whether all associated resources are removed. If any of them is not removed then check what *DeletionPolicy* you have set for the resources which are not removed.


