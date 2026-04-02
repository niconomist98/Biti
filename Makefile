.PHONY: init plan apply destroy fmt validate clean output

ENV     ?= dev
DIR      = infraestructure/live/$(ENV)
TFVARS   = -var-file=terraform.tfvars

# ─── Full lifecycle ───────────────────────────────────────────────────────────

init:
	cd $(DIR) && terraform init -upgrade

plan: init
	cd $(DIR) && terraform plan $(TFVARS)

apply: init
	cd $(DIR) && terraform apply $(TFVARS) -auto-approve

destroy: init
	cd $(DIR) && terraform destroy $(TFVARS) -auto-approve

output:
	cd $(DIR) && terraform output

# ─── Quality ──────────────────────────────────────────────────────────────────

fmt:
	terraform fmt -recursive infraestructure/

validate: init
	cd $(DIR) && terraform validate

# ─── Targeted deploys (apply single layer) ────────────────────────────────────

apply-s3: init
	cd $(DIR) && terraform apply $(TFVARS) -auto-approve -target=module.s3

apply-dynamodb: init
	cd $(DIR) && terraform apply $(TFVARS) -auto-approve -target=module.dynamodb

apply-glue: init
	cd $(DIR) && terraform apply $(TFVARS) -auto-approve \
		-target=aws_s3_object.glue_script -target=module.glue

apply-sagemaker: init
	cd $(DIR) && terraform apply $(TFVARS) -auto-approve -target=module.sagemaker

apply-lambda-inference: init
	cd $(DIR) && terraform apply $(TFVARS) -auto-approve -target=module.lambda_inference

apply-step-functions: init
	cd $(DIR) && terraform apply $(TFVARS) -auto-approve -target=module.step_functions

apply-webapp: init
	cd $(DIR) && terraform apply $(TFVARS) -auto-approve \
		-target=aws_s3_bucket.webapp_frontend \
		-target=aws_cloudfront_distribution.webapp \
		-target=aws_lambda_function.webapp_api \
		-target=aws_apigatewayv2_api.webapp

# ─── Cleanup ──────────────────────────────────────────────────────────────────

clean:
	find infraestructure/ -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find infraestructure/ -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	find infraestructure/ -name "*.tfstate*" -delete 2>/dev/null || true
