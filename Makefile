.PHONY : docker-prune docker-check docker-build docker-push

# To build an image with the latest package versions, change the value of
# CONDA_ENV_FILE to  conda-env-no-version.yml
# CONDA_ENV_FILE := conda-env.yml
CONDA_ENV_FILE := conda-env-no-version.yml
PIP_REQ_FILE := pip-req.txt
VCS_URL := $(shell git remote get-url --push gl)
VCS_REF := $(shell git rev-parse --short HEAD)
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
TAG_DATE := $(shell date -u +"%Y%m%d")
AZ_RG_ACR := rg-ore-infra
AZ_ACR_NAME := acrore
AZ_ACR_ZONE := ${AZ_ZONE}

docker-prune :
	@echo Pruning Docker images/containers/networks not in use
	docker system prune

docker-check :
	@echo Computing reclaimable space consumed by Docker artifacts
	docker system df

docker-build: Dockerfile conda-env*.yml pip-req.txt pip.conf fix-permissions
	@az acr build \
	--registry ${AZ_ACR_NAME} \
	--build-arg CONDA_ENV_FILE=$(CONDA_ENV_FILE) \
	--build-arg PIP_REQ_FILE=$(PIP_REQ_FILE) \
	--build-arg VCS_URL=$(VCS_URL) \
	--build-arg VCS_REF=$(VCS_REF) \
	--build-arg BUILD_DATE=$(BUILD_DATE) \
	--t dedupe-docker:$(TAG_DATE) \
	--t dedupe-docker:latest .

docker-push : docker-build
	@docker push dedupe-docker:$(TAG_DATE)
	@docker push dedupe-docker:latest
