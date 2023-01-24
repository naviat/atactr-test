# Provision Automata Network Fullnode

## Prerequisites

- Install `kubectl`, `eksctl`, `helm` ...

## Tasks

### ---Task 1---

#### Create a new cluster with the following (Because of this task is not required using terraform, I would like to create it manually):

	```shell
	$ cd ./task1/setup
	$ eksctl create cluster -f eks.yml
	```

#### Edit the configuration in `cf-samples.yml`

	```yaml
	apiVersion: v1
	kind: Secret
	metadata:
	  name: cloudflare-api-token-secret
	type: Opaque
	stringData:
	  api-token: *<API global token>*
	```

#### Run `install.sh` from `./task1/setup`
