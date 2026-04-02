.PHONY: init plan apply destroy fmt validate clean

ENV ?= dev
DIR = infraestructure/live/$(ENV)
TF_ARGS = -var="environment=$(ENV)"

init:
	cd $(DIR) && terraform init

plan: init
	cd $(DIR) && terraform plan $(TF_ARGS)

apply: init
	cd $(DIR) && terraform apply $(TF_ARGS) -auto-approve

destroy: init
	cd $(DIR) && terraform destroy $(TF_ARGS) -auto-approve

fmt:
	terraform fmt -recursive infraestructure/

validate: init
	cd $(DIR) && terraform validate

clean:
	find infraestructure/ -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find infraestructure/ -name ".terraform.lock.hcl" -delete 2>/dev/null || true

# Deploy only specific components using -target
apply-s3: init
	cd $(DIR) && terraform apply $(TF_ARGS) -auto-approve -target=module.s3

apply-dynamodb: init
	cd $(DIR) && terraform apply $(TF_ARGS) -auto-approve -target=module.dynamodb

apply-lambda-inference: init
	cd $(DIR) && terraform apply $(TF_ARGS) -auto-approve -target=module.lambda_inference

apply-step-functions: init
	cd $(DIR) && terraform apply $(TF_ARGS) -auto-approve -target=module.step_functions

apply-sagemaker: init
	cd $(DIR) && terraform apply $(TF_ARGS) -auto-approve -target=module.sagemaker
