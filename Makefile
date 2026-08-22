.PHONY: fmt init validate plan

fmt:
	terraform -chdir=terraform fmt -recursive

init:
	terraform -chdir=terraform init

validate: init
	terraform -chdir=terraform validate

plan:
	terraform -chdir=terraform plan
