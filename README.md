# devops-practice-py

FastAPI service with CI quality gates, immutable GHCR images, and a local
Kubernetes deployment managed by Terraform.

## Local development

```bash
uv sync
uv run pytest
uv run uvicorn main:app --reload
```

The same common tasks are available through `make`:

```bash
make install
make test
make coverage
make lint
make format-check
make validate
```

The API exposes `/health` for Kubernetes probes and `/metrics` for Prometheus.

## Local deployment

Create the cluster once:

```bash
kind create cluster --config infra/kind.yaml
```

Deploy an immutable image digest after it has passed CI:

```bash
make deploy IMAGE=ghcr.io/nusretkilic/devops-practice-py@sha256:<64-hex-digest>
```

The script runs Terraform plan and apply, then waits for the rollout. To
practice the recovery path:

```bash
make rollback
```

The GitHub Actions workflow also creates an ephemeral kind cluster on pushes
to `main`, deploys the published digest, and verifies a failed rollout is
recovered with `kubectl rollout undo`.

init