.PHONY: fmt init validate test plan

fmt:
	terraform -chdir=terraform fmt -recursive

init:
	terraform -chdir=terraform init -backend=false

validate: init
	terraform -chdir=terraform validate

test: validate
	terraform -chdir=terraform test

plan:
	terraform -chdir=terraform plan
