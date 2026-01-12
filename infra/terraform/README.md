# Terraform layout

This repo uses a small bootstrap stack to create the remote state bucket (and a legacy lock table), then two environment stacks (dev/prod) that deploy the ECS Fargate service.

## Bootstrap (one-time)

From `infra/terraform/bootstrap`:

```bash
terraform init
terraform apply
```

This creates:
- S3 bucket for Terraform state
- DynamoDB table for legacy state locking (optional when using `use_lockfile`)

## Dev/Prod stacks

From `infra/terraform/envs/dev` or `infra/terraform/envs/prod`:

```bash
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Outputs include the ECR repository URL and the ECS service name.

RDS is included in each environment. Provide the database password using an environment variable before running `plan` or `apply`:

```bash
$env:TF_VAR_db_password = "your-strong-password"
```

Note: This stack currently runs ECS tasks with public IPs and no load balancer (account restriction workaround).
To reach the app, find the running task's public IP in the ECS console and hit `http://<public-ip>:8080/health`.

## GitHub Actions OIDC (for CD)

Create the GitHub OIDC provider + role once:

From `infra/terraform/oidc`:

```bash
terraform init
terraform apply
```

The workflow expects these GitHub Environment secrets:
- `AWS_ROLE_ARN` (role ARN from the OIDC stack output)
- `TF_VAR_DB_PASSWORD` (database password for the environment)
