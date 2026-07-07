.PHOONY = clear init

init:
	@terraform init

plan:
	@terraform plan

apply:
	@terraform apply -auto-approve

destroy:
	@terraform destroy -auto-approve

clean:
	@rm -rf .terraform.lock.hcl
	@rm -rf .terraform
	@rm -f terraform.tfstate.backup
	@rm -f terraform.tfstate