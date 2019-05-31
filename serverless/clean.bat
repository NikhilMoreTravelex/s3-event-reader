REM Should be populated from AWS SSM store
set AWS_ACCESS_KEY_ID=
set AWS_SECRET_ACCESS_KEY=
set AWS_REGION=eu-east-1
set SLS_DEBUG=*

REM SLS clean scripts
sls alias remove --alias=dev
sls remove
