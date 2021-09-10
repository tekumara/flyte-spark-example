MAKEFLAGS += --warn-undefined-variables
SHELL = /bin/bash -o pipefail
.DEFAULT_GOAL := help
.PHONY: help install check lint pyright test hooks install-hooks exec.yaml

export FLYTECTL_CONFIG=$(HOME)/.flyte/config-sandbox.yaml
export KUBECONFIG=$(HOME)/.flyte/k3s/k3s.yaml

name = fspark

## display help message
help:
	@awk '/^##.*$$/,/^[~\/\.0-9a-zA-Z_-]+:/' $(MAKEFILE_LIST) | awk '!(NR%2){print $$0p}{p=$$0}' | awk 'BEGIN {FS = ":.*?##"}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' | sort

venv = .venv
pip := $(venv)/bin/pip

$(pip):
	# create empty virtualenv containing pip
	$(if $(value VIRTUAL_ENV),$(error Cannot create a virtualenv when running in a virtualenv. Please deactivate the current virtual env $(VIRTUAL_ENV)),)
	python3 -m venv --clear $(venv)
	$(pip) install pip==21.2.4 setuptools==57.4.0 wheel==0.37.0

$(venv): setup.py $(pip)
	$(pip) install -e '.[dev]'
	touch $(venv)

## create venv and install this package and hooks
install: $(venv) node_modules $(if $(value CI),,install-hooks)

## format all code
format: $(venv)
	$(venv)/bin/black .
	$(venv)/bin/isort .

## lint code and run static type check
check: lint pyright

## lint using flake8
lint: $(venv)
	$(venv)/bin/flake8

node_modules: package.json
	npm install --no-save
	touch node_modules

## pyright
pyright: node_modules $(venv)
	source $(venv)/bin/activate && node_modules/.bin/pyright

## run tests
test: $(venv)
	$(venv)/bin/pytest

## run job locally
run: $(venv)
	$(venv)/bin/python fspark/main.py

## create and start the sandbox (mounting the current dir)
sandbox-create:
	flytectl sandbox start --source .

## start the sandbox
sandbox-start:
	docker start flyte-sandbox
	@echo Flyte UI is available at http://localhost:30081/console
	@echo Add KUBECONFIG and FLYTECTL_CONFIG to your environment variable
	@echo 'export KUBECONFIG=$$KUBECONFIG:$(HOME)/.kube/config:$(HOME)/.flyte/k3s/k3s.yaml'
	@echo 'export FLYTECTL_CONFIG=$(HOME)/.flyte/config-sandbox.yaml'

## enter shell in sandbox
sandbox-shell:
	docker exec -it flyte-sandbox /bin/bash

## build the docker container inside the sandbox
build:
	flytectl sandbox exec -- docker build . --tag $(name):$(version)

## package (serialise to protobuf)
package: $(venv)
	$(venv)/bin/pyflyte package -f --image $(name):$(version)

## register
register:
	flytectl register files --project flyteexamples --domain development --archive flyte-package.tgz --version $(version)

exec.yaml:
	rm -f exec.yaml
	flytectl get launchplan -p flyteexamples -d development $(name).main.my_spark --execFile exec.yaml

## create execution spec for launchplan
launchplan: exec.yaml

## execute
exec: exec.yaml
	flytectl create execution --project flyteexamples --domain development --execFile exec.yaml
	@echo -e "\nVisit http://localhost:30081/console/projects/flyteexamples/domains/development/workflows/fspark.main.my_spark"

## enable the spark plugin (restarts flytepropeller)
enable-spark:
	kubectl -n flyte patch configmap flyte-propeller-config --patch-file config/enable_spark_patch.yaml
	kubectl -n flyte patch configmap clusterresource-template --patch-file config/spark_rbac_patch.yaml
	kubectl -n flyte rollout restart deployment/flytepropeller
	# enable ingress: *.vcap.me resolves to 127.0.0.1
	kubectl -n flyte patch deployment flyte-sparkoperator --type json -p '[{"op": "replace", "path": "/spec/template/spec/containers/0/args/3", "value":"-ingress-url-format={{$$appName}}.vcap.me"}]'
	kubectl -n flyte rollout restart deployment/flyte-sparkoperator

## install the spark operator
install-spark-operator:
	helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operator
	helm install flyte-spark spark-operator/spark-operator --namespace spark-operator --create-namespace --set ingressUrlFormat='/{{$$appNamespace}}/{{$$appName}}'

## uninstall the spark operator
uninstall-spark-operator:
	helm uninstall flyte-spark --namespace spark-operator
	kubectl delete serviceaccount flyte-spark-spark-operator --namespace spark-operator

## list spark apps
get-sparkapplication:
	 kubectl get sparkapplication -n flyteexamples-development

## watch spark ui ingress paths
watch-sparkui:
	kubectl get ingress -n flyteexamples-development -w -o jsonpath='http://{.spec.rules[*].host}:30081{"\n"}' -w

## dump propeller configmap
propeller-config:
	kubectl get configmap -n flyte flyte-propeller-config -o yaml

## run pre-commit git hooks on all files
hooks: $(venv)
	$(venv)/bin/pre-commit run --show-diff-on-failure --color=always --all-files --hook-stage push

install-hooks: .git/hooks/pre-commit .git/hooks/pre-push

.git/hooks/pre-commit: $(venv)
	$(venv)/bin/pre-commit install -t pre-commit

.git/hooks/pre-push: $(venv)
	$(venv)/bin/pre-commit install -t pre-push
