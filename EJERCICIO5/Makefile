.PHONY = clean init

init:
	@terraform init

plan:
	@terraform plan

apply:
	@terraform apply -auto-approve

destroy:
	@terraform destroy -auto-approve

format:
	@terraform fmt

clean:
	@rm -rf .terraform.lock.hcl
	@rm -rf .terraform
	@rm -f terraform.tfstate
	@rm -f terraform.tfstate.backup