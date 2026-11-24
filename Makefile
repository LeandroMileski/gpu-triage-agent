REGION ?= us-east-1
CLUSTER ?= k8s-debug-demo
IMAGE ?= triage-agent

.PHONY: up pause down kubeconfig image-push test validate

up:
	terraform -chdir=terraform init
	terraform -chdir=terraform apply

pause:
	terraform -chdir=terraform apply -var node_count=0

down:
	terraform -chdir=terraform destroy

kubeconfig:
	aws eks update-kubeconfig --name $(CLUSTER) --region $(REGION)

image-push:
	ACCOUNT=$$(aws sts get-caller-identity --query Account --output text); \
	URI="$$ACCOUNT.dkr.ecr.$(REGION).amazonaws.com/$(IMAGE)"; \
	aws ecr get-login-password --region $(REGION) | docker login --username AWS --password-stdin "$$ACCOUNT.dkr.ecr.$(REGION).amazonaws.com"; \
	docker build -t "$$URI:latest" agent; \
	docker push "$$URI:latest"; \
	URI="$$URI" python3 -c 'import os,re; from pathlib import Path; p=Path("cluster/kustomization.yaml"); t=p.read_text(); p.write_text(re.sub(r"newName: .*","newName: "+os.environ["URI"], t, count=1))'; \
	echo "Image pushed. Commit cluster/kustomization.yaml so Argo CD pulls $$URI:latest"

test:
	python3 -m unittest discover -s agent -v

validate:
	terraform -chdir=terraform fmt -check -recursive
	terraform -chdir=terraform init -backend=false
	terraform -chdir=terraform validate
	kubectl kustomize cluster >/dev/null
