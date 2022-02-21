# Global Forest Watch Mail API

This repository is the microservice that send the emails.

## Getting Started

**First, make sure that you have the [API gateway running
locally](https://github.com/wri/fw_api).**

Start by cloning the repository from github to your execution environment

```
git clone https://github.com/wri/fw_mail.git && cd fw_mail
```

After that, follow one of the instructions below:

### Using Docker

1 - Execute the following command to run Docker:

```shell
make up-and-build   # First time building Docker or you've made changes to the Dockerfile
make up             # When Docker has already been built and you're starting from where you left off
```

The endpoints provided by this microservice should now be available: [localhost:3500](http://localhost:3500)

2 - Run the following command to lint the project:

```shell
make lint
```

3 - To close Docker:

```shell
make down
```

## Testing

### Using Docker

Follow the instruction above for setting up the runtime environment for Docker execution, then run:
```shell
make test-and-build
```

### Configuration

It is necessary to define these environment variables:

* API_GATEWAY_URI => Gateway Service API URL
* NODE_ENV => Environment (prod, staging, dev)
* API_GATEWAY_QUEUE_URL => Url of async queue
* API_GATEWAY_QUEUE_PROVIDER => redis (only support redis)
* SELF_REGISTRY => on/off to set auto registry in API Gateway
* SPARKPOST_API_KEY => Sparkpost api key to send emails
