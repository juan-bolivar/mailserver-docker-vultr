.phony: run delete

run:
	terraform init
	terraform plan
	terraform apply
delete:
	terraform destroy
