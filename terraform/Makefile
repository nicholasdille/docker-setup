-include ../.env.mk

.PHONY:
clean:
	@rm -rf plan.out terraform.tfstate* ssh*

.PHONY:
show:
	@terraform show

.PHONY:
output:
	@terraform output

.PHONY:
init: .terraform.lock.hcl

.terraform.lock.hcl:
	@terraform init

ssh:
	@ssh-keygen -t ed25519 -f ssh -N ''

.PHONY:
plan: plan.out

plan.out: *.tf ssh .terraform.lock.hcl
	@terraform plan -out=plan.out -var="hcloud_token=$(HCLOUD_TOKEN)" -var="hetznerdns_token=$(HETZNERDNS_TOKEN)"

.PHONY:
apply: terraform.tfstate

terraform.tfstate: plan.out
	@terraform apply -auto-approve -state=terraform.tfstate plan.out
	@rm -f plan.out

.PHONY:
destroy: terraform.tfstate
	@terraform destroy -auto-approve -state=terraform.tfstate -var="hcloud_token=$(HCLOUD_TOKEN)" -var="hetznerdns_token=$(HETZNERDNS_TOKEN)"
	@rm -f terraform.tfstate*

# State management
# https://github.com/plumber-cd/terraform-backend-git
#tfstate:
#	@terraform state pull
