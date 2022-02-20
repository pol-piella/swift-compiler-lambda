# CompilerLambda

This project builds and deploys a Lambda function that runs Swift code. This is similar to using the the Swift REPL locally, but opens up the possibility of running this in the cloud.

Since the code needs access to a Swift toolchain, a custom docker image is built and deployed to AWS ECR. The Lambda then can be configured to using the latest version of the deployed image.

## Build and deploy

```bash
docker build . -t compiler-lambda

docker tag compiler-lambda:latest <Account_ID>.dkr.ecr.<Region>.amazonaws.com/compiler-lambda:latest

docker push <Account_ID>.dkr.ecr.<Region>.amazonaws.com/compiler-lambda
```