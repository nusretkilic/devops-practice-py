.PHONY: help install test coverage lint format format-check validate terraform-init \
	kind-create deploy rollback docker-build

IMAGE ?= ghcr.io/nusretkilic/devops-practice-py@sha256:<64-hex-digest>
IMAGE_TAG ?= devops-practice:local

help:
	@echo "Available targets:"
	@echo "  install       Install locked project dependencies"
	@echo "  test          Run the test suite"
	@echo "  coverage      Run tests with coverage output"
	@echo "  lint          Run Ruff lint checks"
	@echo "  format        Format Python files with Ruff"
	@echo "  format-check  Check Python and Terraform formatting"
	@echo "  validate      Validate Terraform configuration"
	@echo "  kind-create   Create the local kind cluster"
	@echo "  deploy        Deploy an immutable image with Terraform"
	@echo "  rollback      Roll back the Kubernetes deployment"
	@echo "  docker-build  Build the local container image"

install:
	uv sync --locked

test:
	uv run --locked python -m pytest -v

coverage:
	uv run --locked python -m pytest -v --cov=main --cov-report=term-missing \
		--cov-fail-under=80

lint:
	uv run --locked ruff check .

format:
	uv run --locked ruff format .

format-check:
	uv run --locked ruff format --check .
	terraform -chdir=infra/terraform fmt -check

validate:
	terraform -chdir=infra/terraform validate

terraform-init:
	terraform -chdir=infra/terraform init -upgrade=false

kind-create:
	kind create cluster --config infra/kind.yaml --name devops-practice

deploy:
	@test "$(IMAGE)" != "ghcr.io/nusretkilic/devops-practice-py@sha256:<64-hex-digest>" || \
		(echo "Set IMAGE to an immutable GHCR sha256 digest." >&2; exit 1)
	@test "$(IMAGE)" = "$$(printf '%s' "$(IMAGE)" | grep -E '^ghcr\.io/nusretkilic/devops-practice-py@sha256:[0-9a-f]{64}$$')" || \
		(echo "IMAGE must be this repository's full sha256 digest." >&2; exit 1)
	terraform -chdir=infra/terraform init -upgrade=false
	terraform -chdir=infra/terraform plan -var="image=$(IMAGE)"
	terraform -chdir=infra/terraform apply -auto-approve -var="image=$(IMAGE)"
	kubectl -n devops-practice rollout status deployment/devops-practice --timeout=180s
	kubectl -n devops-practice get deployment,service,pods

rollback:
	kubectl -n devops-practice rollout undo deployment/devops-practice
	kubectl -n devops-practice rollout status deployment/devops-practice --timeout=180s
	kubectl -n devops-practice get deployment devops-practice \
		-o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

docker-build:
	docker build --tag "$(IMAGE_TAG)" .
