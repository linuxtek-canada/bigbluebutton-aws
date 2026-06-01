# GitHub Secrets Configuration

Configure these secrets in your forked repository settings (Settings > Secrets and variables > Actions).

## Required Secrets

### AWS OIDC Role ARNs

| Secret | Description | Example |
|--------|-------------|---------|
| `AWS_ROLE_ARN_BOOTSTRAP` | Existing IAM role for bootstrap workflow | `arn:aws:iam::586794440352:role/GitHubAction-AssumeRoleWithAction` |
| `AWS_ROLE_ARN_DEV` | Per-env role created by bootstrap (dev) | `arn:aws:iam::586794440352:role/bigbluebutton-dev-github-actions` |
| `AWS_ROLE_ARN_PROD` | Per-env role created by bootstrap (prod) | `arn:aws:iam::586794440352:role/bigbluebutton-prod-github-actions` |

### SSH Key (for Ansible provisioning)

| Secret | Description | Used By |
|--------|-------------|---------|
| `SSH_PRIVATE_KEY` | Full PEM content of the SSH private key used to access EC2 instances | dev, prod |

### Terraform Variables (injected as TF_VAR_*)

| Secret | Description | Used By |
|--------|-------------|---------|
| `TF_VAR_KEY_NAME` | Name of SSH key pair in AWS | dev, prod |
| `TF_VAR_ALLOWED_SSH_CIDRS` | JSON list of CIDR blocks for SSH access | dev, prod |
| `TF_VAR_DOMAIN_NAME_DEV` | Domain name for dev BBB instance | dev |
| `TF_VAR_DOMAIN_NAME_PROD` | Domain name for prod BBB instance | prod |
| `TF_VAR_ADMIN_EMAIL` | Admin email for Let's Encrypt and alerts | dev, prod |
| `TF_VAR_BBB_ADMIN_PASSWORD` | BBB admin password (optional, auto-generated if empty) | dev, prod |

### Optional Secrets

| Secret | Description | Used By |
|--------|-------------|---------|
| `TF_VAR_ADMIN_DOMAIN_NAME` | Custom domain for admin dashboard | prod |
| `TF_VAR_ADMIN_ACM_CERTIFICATE_ARN` | ACM certificate ARN for admin dashboard | prod |
| `TF_VAR_MONTHLY_BUDGET_LIMIT_DEV` | Monthly AWS budget cap for dev | dev |
| `TF_VAR_MONTHLY_BUDGET_ALERT_DEV` | Budget alert threshold for dev | dev |
| `TF_VAR_MONTHLY_BUDGET_LIMIT_PROD` | Monthly AWS budget cap for prod | prod |
| `TF_VAR_MONTHLY_BUDGET_ALERT_PROD` | Budget alert threshold for prod | prod |

## Secret Format Examples

**TF_VAR_ALLOWED_SSH_CIDRS:**
```
["203.0.113.0/24", "198.51.100.5/32"]
```

**SSH_PRIVATE_KEY:**
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
-----END RSA PRIVATE KEY-----
```

## Deployment Order

1. Set `AWS_ROLE_ARN_BOOTSTRAP` (use existing broad role)
2. Run `Terraform Bootstrap` workflow
3. Copy role ARNs from bootstrap output
4. Set `AWS_ROLE_ARN_DEV` and `AWS_ROLE_ARN_PROD`
5. Set remaining `TF_VAR_*` secrets
6. Run `Terraform Apply - Dev` workflow
7. Validate dev environment
8. Run `Terraform Apply - Prod` workflow
