# BigBlueButton Infrastructure

Terraform and Ansible infrastructure for deploying BigBlueButton video conferencing on AWS with a serverless admin dashboard.

## Features

* **BigBlueButton Server**: EC2 instance (m6a.2xlarge) with Ubuntu, auto-provisioned via remote-exec
* **Custom VPC**: Isolated network with security groups for WebRTC traffic
* **S3 Recording Storage**: Encrypted bucket with lifecycle policies and automatic sync
* **Admin Dashboard**: Serverless web UI (CloudFront + Lambda + API Gateway) with Cognito authentication
* **VM Controls**: Start/stop EC2 instance from the admin dashboard
* **GitOps Deployment**: GitHub Actions with OIDC authentication (no static credentials)
* **Ansible Playbooks**: Alternative installation method with full templating
* **AWS Well-Architected**: Full implementation across all 6 pillars (security, reliability, cost, operations, performance, sustainability)
* **Budget Controls**: Alert at $100 USD with automatic resource shutdown at $200 USD
* **Security Controls**: WAF, CloudTrail, GuardDuty, AWS Config compliance rules

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                    AWS                                        │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                              VPC (10.x.0.0/16)                          │ │
│  │  ┌───────────────────────────────────────────────────────────────────┐  │ │
│  │  │                        Public Subnet                               │  │ │
│  │  │  ┌─────────────────────────────────────────────────────────────┐  │  │ │
│  │  │  │                  EC2 (BigBlueButton)                        │  │  │ │
│  │  │  │  * Ubuntu 22.04/24.04  * m6a.2xlarge  * Elastic IP         │  │  │ │
│  │  │  │  * EBS gp3 (KMS encrypted in prod)  * IMDSv2 required      │  │  │ │
│  │  │  └─────────────────────────────────────────────────────────────┘  │  │ │
│  │  │                                                                    │  │ │
│  │  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │  │ │
│  │  │  │ S3 VPC Endpoint │  │ SSM VPC Endpoint│  │ VPC Flow Logs   │   │  │ │
│  │  │  │    (Gateway)    │  │  (Interface)    │  │                 │   │  │ │
│  │  │  └─────────────────┘  └─────────────────┘  └─────────────────┘   │  │ │
│  │  └───────────────────────────────────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                         Admin Dashboard                                  │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │ │
│  │  │  CloudFront  │  │   AWS WAF    │  │  API Gateway │  │   Lambda   │  │ │
│  │  │     CDN      │──│  (Managed    │──│    REST      │──│  EC2 Ctrl  │  │ │
│  │  │              │  │   Rules)     │  │              │  │  S3 List   │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘  │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                         Security & Compliance                            │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │ │
│  │  │  CloudTrail  │  │  GuardDuty   │  │  AWS Config  │  │    KMS     │  │ │
│  │  │  (Audit Log) │  │  (Threats)   │  │  (Compliance)│  │   (CMK)    │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘  │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                         Monitoring & Alerts                              │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │ │
│  │  │  CloudWatch  │  │  CloudWatch  │  │     SNS      │  │   Route53  │  │ │
│  │  │  Dashboard   │  │   Alarms     │  │   Topics     │  │Health Check│  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘  │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                         Cost & Backup                                    │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │ │
│  │  │ AWS Budgets  │  │  Budget      │  │  AWS Backup  │  │ EventBridge│  │ │
│  │  │ $100/$200    │──│  Enforcer    │  │  (EBS Daily) │  │ Auto Stop  │  │ │
│  │  │              │  │  Lambda      │  │              │  │            │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘  │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                        │
│  │ S3 Recordings│  │   Cognito    │  │  S3 CloudTrail│                       │
│  │   Bucket     │  │  User Pool   │  │    Logs       │                       │
│  └──────────────┘  └──────────────┘  └──────────────┘                        │
└──────────────────────────────────────────────────────────────────────────────┘
```

## AWS Well-Architected Framework

This infrastructure implements AWS Well-Architected best practices across all six pillars:

### Security Pillar
* **AWS WAF**: Web Application Firewall on CloudFront with managed rule sets (Common, Known Bad Inputs, SQLi) and rate limiting
* **CloudTrail**: Multi-region audit logging with S3 storage and CloudWatch integration
* **GuardDuty**: Threat detection with S3 malware protection and SNS alerts for high-severity findings
* **AWS Config**: Compliance rules for encrypted volumes, SSL enforcement, and SSM management
* **KMS**: Customer-managed keys for EBS and S3 encryption (production)
* **IMDSv2**: Instance metadata service v2 enforced
* **VPC Flow Logs**: Network traffic logging enabled

### Reliability Pillar
* **AWS Backup**: Automated EBS backups with daily (7 days), weekly (30 days), and monthly (1 year) retention
* **Route 53 Health Checks**: HTTPS health monitoring on BigBlueButton API endpoint
* **CloudWatch Alarms**: Status checks, CPU utilization (80%/95% thresholds), EBS queue length
* **SNS Notifications**: Email alerts for all alarm state changes

### Operational Excellence Pillar
* **CloudWatch Dashboard**: Centralized view of EC2, EBS, S3, and alarm metrics
* **VPC Endpoints**: S3 Gateway endpoint (free) and optional SSM Interface endpoints for private access
* **SSM Session Manager**: Secure shell access without SSH key management (via VPC endpoints)

### Cost Optimization Pillar
* **AWS Budgets**: Alert threshold at $100 USD and hard limit at $200 USD
* **Auto-Stop Lambda**: Automatically stops EC2 instances when budget limit is reached
* **Auto Stop/Start**: EventBridge rules to stop dev instances outside business hours
* **S3 Lifecycle**: Automatic transition to Glacier after configured retention period
* **Intelligent-Tiering**: Automatic storage class optimization for varying access patterns

### Performance Efficiency Pillar
* **Enhanced Monitoring**: 1-minute CloudWatch metrics for EC2
* **gp3 EBS Volumes**: High-performance SSD with configurable IOPS
* **CloudFront CDN**: Global content delivery for admin dashboard

### Sustainability Pillar
* **Scheduled Scaling**: Auto-stop dev instances outside business hours (10 PM - 8 AM UTC)
* **Right-sizing**: m6a.2xlarge optimized for BigBlueButton workloads

### Environment Differences

| Feature | Dev | Prod |
|---------|-----|------|
| AWS Backup | Disabled | Daily/Weekly/Monthly |
| KMS CMK | Disabled | Enabled |
| VPC Endpoints | Disabled | SSM endpoints enabled |
| Health Check | Disabled | Enabled |
| Auto Stop/Start | Enabled (cost savings) | Disabled (24/7) |
| CloudTrail S3 Events | Disabled | Enabled |
| AWS Config | Disabled | Enabled |
| WAF Rate Limit | 1000 req/5min | 500 req/5min |

## Prerequisites

* AWS Account with admin access
* GitHub repository (for GitOps)
* Terraform >= 1.5.0
* AWS CLI v2
* Python 3.11+ (for Ansible)
* Domain name (optional but recommended for HTTPS)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_ORG/YOUR_REPO.git
cd YOUR_REPO
```

### 2. Bootstrap AWS Infrastructure

The bootstrap creates:
* GitHub OIDC provider for keyless authentication
* S3 buckets for Terraform state (per environment)
* DynamoDB tables for state locking
* IAM roles for GitHub Actions

#### Option A: Local Bootstrap (Recommended for First Setup)

```bash
cd bootstrap

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values:
#   github_org  = "your-github-username-or-org"
#   github_repo = "your-repo-name"

# Authenticate with AWS (admin credentials required)
aws configure
# OR
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx

# Run bootstrap
terraform init
terraform plan
terraform apply

# Note the outputs - you'll need them for GitHub secrets
terraform output -json
```

#### Option B: GitHub Actions Bootstrap

1. Create an IAM user with admin permissions for initial bootstrap
2. Add the following GitHub repository secrets:
   * `BOOTSTRAP_ROLE_ARN`: ARN of the admin IAM role
3. Run the "Bootstrap Infrastructure" workflow manually

### 3. Configure GitHub Secrets

After bootstrap, add these secrets to your GitHub repository.
See [docs/GITHUB_SECRETS.md](docs/GITHUB_SECRETS.md) for the full list.

Key secrets required:

| Secret | Description | Example |
|--------|-------------|---------|
| `AWS_ROLE_ARN_BOOTSTRAP` | Existing IAM role for bootstrap | `arn:aws:iam::586794440352:role/GitHubAction-AssumeRoleWithAction` |
| `AWS_ROLE_ARN_DEV` | Per-env role (from bootstrap output) | `arn:aws:iam::586794440352:role/bigbluebutton-dev-github-actions` |
| `AWS_ROLE_ARN_PROD` | Per-env role (from bootstrap output) | `arn:aws:iam::586794440352:role/bigbluebutton-prod-github-actions` |
| `TF_VAR_KEY_NAME` | AWS EC2 key pair name | `bigbluebutton-key` |
| `TF_VAR_ALLOWED_SSH_CIDRS` | JSON array of allowed CIDRs | `["10.0.0.0/8"]` |
| `TF_VAR_DOMAIN_NAME_PROD` | BBB domain (prod) | `bbb.example.com` |
| `TF_VAR_ADMIN_EMAIL` | Email for Let's Encrypt + alerts | `admin@example.com` |

### 5. Create SSH Key Pair

```bash
# Create key pair in AWS
aws ec2 create-key-pair \
  --key-name bigbluebutton-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/bigbluebutton-key.pem

chmod 600 ~/.ssh/bigbluebutton-key.pem

# Add the private key content to GitHub secrets as SSH_PRIVATE_KEY
```

### 5. Deploy Infrastructure

#### Via GitHub Actions (Recommended)

All deployments use manual `workflow_dispatch` triggers:

1. Go to Actions tab in your GitHub repository
2. Run "Terraform Apply - Dev" workflow
3. Validate dev environment
4. Run "Terraform Apply - Prod" workflow

Available workflows:
* **Terraform Bootstrap** - One-time state backend setup
* **Terraform Apply - Dev** - Deploy dev environment
* **Terraform Apply - Prod** - Deploy prod environment
* **Terraform Destroy - Dev** - Tear down dev
* **Terraform Destroy - Prod** - Tear down prod
* **Terraform State Unlock** - Force-unlock stuck state

#### Via Local Terraform

```bash
cd environments/dev

# Initialize with S3 backend
terraform init

# Create tfvars file
cat > terraform.tfvars <<EOF
# Required
key_name          = "bigbluebutton-key"
admin_email       = "admin@example.com"
allowed_ssh_cidrs = ["YOUR_IP/32"]

# Optional but recommended
domain_name       = "bbb.example.com"

# Provisioning
enable_provisioning  = true
ssh_private_key_path = "~/.ssh/bigbluebutton-key.pem"

# Cost controls (defaults: alert at $100, stop at $200)
monthly_budget_alert = 100
monthly_budget_limit = 200

# Auto stop/start schedule (dev only, UTC times)
auto_stop_schedule  = "cron(0 22 ? * MON-FRI *)"  # 10 PM UTC
auto_start_schedule = "cron(0 12 ? * MON-FRI *)"  # 12 PM UTC

# Security features (all enabled by default)
enable_cloudtrail = true
enable_guardduty  = true
enable_waf        = true
EOF

# Plan and apply
terraform plan
terraform apply
```

### 7. Configure DNS

After deployment, point your domain to the Elastic IP:

```bash
# Get the Elastic IP
terraform output instance_public_ip

# Create DNS A record:
# bbb.example.com -> Elastic IP
```

### 8. Access the Admin Dashboard

```bash
# Get the dashboard URL
terraform output admin_dashboard_url

# First login:
# 1. Go to the CloudFront URL
# 2. Use the admin email you configured
# 3. Check email for temporary password
# 4. Change password on first login
```

### 9. Confirm SNS Email Subscriptions (Required)

After deployment, you must confirm email subscriptions for alerts to work:

```bash
# Check your email for subscription confirmations from:
# 1. CloudWatch Alerts SNS topic (bigbluebutton-{env}-alerts)
# 2. Budget Alerts SNS topic (bigbluebutton-{env}-budget-alerts)

# Click "Confirm subscription" in each email
# Without confirmation, you will NOT receive alerts!
```

### 10. Verify Well-Architected Features

After deployment, verify the security and monitoring features:

```bash
# Get CloudWatch Dashboard URL
terraform output cloudwatch_dashboard_url

# Verify GuardDuty is enabled
aws guardduty list-detectors --region ca-central-1

# Verify CloudTrail is logging
aws cloudtrail get-trail-status --name bigbluebutton-{env}-trail --region ca-central-1

# Verify AWS Backup vault (prod only)
aws backup list-backup-vaults --region ca-central-1

# Verify Budget alerts
aws budgets describe-budgets --account-id $(aws sts get-caller-identity --query Account --output text)
```

## Directory Structure

```
.
├── .github/
│   ├── actions/
│   │   └── aws-login-action/     # Composite OIDC action
│   └── workflows/
│       ├── terraform-bootstrap.yml    # One-time state backend setup
│       ├── terraform-apply-dev.yml    # Deploy dev environment
│       ├── terraform-apply-prod.yml   # Deploy prod environment
│       ├── terraform-destroy-dev.yml  # Tear down dev
│       ├── terraform-destroy-prod.yml # Tear down prod
│       └── terraform-state-unlock.yml # Force-unlock stuck state
├── ansible/
│   ├── playbooks/                # Ansible playbooks
│   ├── roles/bigbluebutton/      # BBB installation role
│   ├── group_vars/               # Variables
│   └── inventory/                # Host inventory
├── bootstrap/                    # OIDC + state infrastructure
├── docs/
│   └── GITHUB_SECRETS.md         # Secret configuration guide
├── environments/
│   ├── dev/                      # Dev environment
│   │   ├── backend.tf            # S3 state backend config
│   │   ├── terraform.tfvars      # Non-secret variable values
│   │   └── ...
│   └── prod/                     # Production environment
│       ├── backend.tf            # S3 state backend config
│       ├── terraform.tfvars      # Non-secret variable values
│       └── ...
├── modules/
│   ├── bigbluebutton/            # EC2, VPC, S3, IAM, monitoring
│   │   ├── auto_stop.tf          # EventBridge auto stop/start
│   │   ├── backup.tf             # AWS Backup
│   │   ├── dashboard.tf          # CloudWatch dashboard
│   │   ├── health_checks.tf      # Route 53 health checks
│   │   ├── kms.tf                # KMS customer managed keys
│   │   ├── monitoring.tf         # CloudWatch alarms
│   │   ├── sns.tf                # SNS topics for alerts
│   │   └── vpc_endpoints.tf      # VPC endpoints
│   ├── admin-dashboard/          # CloudFront, Lambda, Cognito
│   │   └── waf.tf                # AWS WAF WebACL
│   ├── security/                 # Security controls
│   │   ├── cloudtrail.tf         # CloudTrail logging
│   │   ├── config_rules.tf       # AWS Config rules
│   │   └── guardduty.tf          # GuardDuty threat detection
│   └── cost/                     # Cost management
│       └── budgets.tf            # AWS Budgets + auto-stop Lambda
├── tests/                        # Linting scripts
├── .gitignore                    # Version control exclusions
└── Makefile                      # Common commands
```

## Makefile Commands

```bash
make help           # Show all commands
make lint           # Run all linting (Terraform + Ansible)
make test           # Run all tests
make fmt            # Format Terraform files
make ansible-lint   # Run Ansible linting only
make checkov        # Run security scan
make init-dev       # Initialize dev environment
make plan-dev       # Plan dev environment
make init-prod      # Initialize prod environment
make plan-prod      # Plan prod environment
make clean          # Remove temporary files
```

## Security Groups

The following ports are opened for BigBlueButton:

| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH (restricted to allowed CIDRs) |
| 80 | TCP | HTTP (Let's Encrypt, redirects to HTTPS) |
| 443 | TCP | HTTPS (main web interface) |
| 443 | UDP | TURN over UDP (firewall traversal) |
| 16384-32768 | UDP | WebRTC media (FreeSWITCH) |

## User Accounts

The provisioner creates two users on the BigBlueButton server:

| User | Purpose | Access |
|------|---------|--------|
| `bigbluebutton` | Service account | No login shell |
| `bbb-admin` | Administrator | SSH + sudo for bbb-* commands |

Admin credentials are saved to `/root/.bbb-admin-credentials` on the server.

## S3 Recording Sync

Recordings are automatically synced to S3:

* **Sync frequency**: Every 15 minutes (cron job)
* **Immediate upload**: Post-publish hook uploads new recordings
* **Cleanup**: Local recordings deleted after retention period (30 days dev, 90 days prod)
* **Lifecycle**: Transition to Glacier after configured days

## Troubleshooting

### Bootstrap Fails

```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify GitHub repo name matches
cat bootstrap/terraform.tfvars
```

### OIDC Authentication Fails

```bash
# Verify the OIDC provider exists
aws iam list-open-id-connect-providers

# Check role trust policy
aws iam get-role --role-name bigbluebutton-dev-github-actions
```

### Terraform State Lock

```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

### BigBlueButton Installation Fails

```bash
# SSH to the instance
ssh -i ~/.ssh/bigbluebutton-key.pem ubuntu@ELASTIC_IP

# Check installation log
sudo cat /var/log/bbb-install.log

# Check BBB status
sudo bbb-conf --check
```

### Admin Dashboard Login Issues

```bash
# Reset Cognito user password
aws cognito-idp admin-set-user-password \
  --user-pool-id POOL_ID \
  --username admin@example.com \
  --password NewPassword123! \
  --permanent
```

### Not Receiving Alert Emails

```bash
# Check SNS subscription status
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_alerts_topic_arn)

# If status is "PendingConfirmation", check your spam folder
# or re-subscribe manually:
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_alerts_topic_arn) \
  --protocol email \
  --notification-endpoint your-email@example.com
```

### Budget Auto-Stop Not Working

```bash
# Check Lambda function logs
aws logs tail /aws/lambda/bigbluebutton-dev-budget-enforcer --follow

# Verify budget notification is configured
aws budgets describe-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget-name bigbluebutton-dev-monthly-limit

# Manually test the Lambda (will stop instances!)
aws lambda invoke \
  --function-name bigbluebutton-dev-budget-enforcer \
  --payload '{}' \
  response.json
```

### WAF Blocking Legitimate Requests

```bash
# Check WAF logs for blocked requests
aws logs filter-log-events \
  --log-group-name aws-waf-logs-bigbluebutton-dev \
  --filter-pattern "BLOCK" \
  --region us-east-1

# View WAF rule metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=bigbluebutton-dev-waf Name=Rule,Value=RateLimitRule \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum \
  --region us-east-1
```

### CloudWatch Alarms Not Triggering

```bash
# Check alarm state
aws cloudwatch describe-alarms \
  --alarm-name-prefix bigbluebutton-dev \
  --region ca-central-1

# Force alarm state for testing (resets automatically)
aws cloudwatch set-alarm-state \
  --alarm-name bigbluebutton-dev-ec2-cpu-high \
  --state-value ALARM \
  --state-reason "Manual test" \
  --region ca-central-1
```

### Instance Stopped Unexpectedly

Check if budget limit was reached or auto-stop schedule triggered:

```bash
# Check EC2 state change events
aws ec2 describe-instance-status --instance-ids i-xxxxx

# Check EventBridge auto-stop rule (dev only)
aws events list-rules --name-prefix bigbluebutton-dev-auto

# Check budget enforcer Lambda invocations
aws logs filter-log-events \
  --log-group-name /aws/lambda/bigbluebutton-dev-budget-enforcer \
  --filter-pattern "Stopping instances"

# Manually start the instance
aws ec2 start-instances --instance-ids i-xxxxx
```

## Upgrading BigBlueButton

To upgrade BigBlueButton version:

1. Update `bbb_version` variable (e.g., `jammy-300` to `noble-310`)
2. SSH to the server and run the install script:

```bash
ssh bbb-admin@bbb.example.com
wget -qO- https://raw.githubusercontent.com/bigbluebutton/bbb-install/v3.0.x-release/bbb-install.sh | \
  sudo bash -s -- -v NEW_VERSION -s bbb.example.com -e admin@example.com -w -g
```

## Cost Estimation

Approximate monthly costs (ca-central-1):

| Resource | Specification | Est. Cost |
|----------|---------------|-----------|
| EC2 m6a.2xlarge | On-demand, 24/7 | ~$250 |
| EBS gp3 100GB | Root volume | ~$8 |
| Elastic IP | Associated | $0 |
| S3 | 100GB recordings | ~$2.30 |
| CloudFront | Light usage | ~$1 |
| Lambda | Light usage | ~$0 |
| API Gateway | Light usage | ~$0 |
| DynamoDB | On-demand | ~$0 |
| AWS WAF | WebACL + rules | ~$6 |
| CloudTrail | Events + S3 | ~$2 |
| GuardDuty | Threat detection | ~$5 |
| AWS Backup | EBS snapshots | ~$5 |
| VPC Endpoints (prod) | 3x Interface endpoints | ~$22 |

**Dev Total**: ~$280/month (reduced with auto-stop: ~$100/month)
**Prod Total**: ~$300/month (can reduce with Reserved Instances or Savings Plans)

### Budget Controls

This infrastructure includes automatic cost controls:

* **Alert Threshold**: Email notification at $100 USD/month (80% and 100%)
* **Hard Limit**: Auto-stop EC2 instances at $200 USD/month
* **Dev Auto-Stop**: Instances stop at 10 PM UTC and start at 12 PM UTC (weekdays only)

To modify budget thresholds, update `monthly_budget_alert` and `monthly_budget_limit` in terraform.tfvars.

### Disabling Features to Reduce Costs

You can disable optional features in terraform.tfvars:

```hcl
# Disable security features (not recommended for production)
enable_cloudtrail = false  # Saves ~$2/month
enable_guardduty  = false  # Saves ~$5/month
enable_waf        = false  # Saves ~$6/month

# Dev environment only
enable_backups       = false  # Already disabled in dev
enable_kms           = false  # Already disabled in dev
enable_ssm_endpoints = false  # Already disabled in dev
enable_health_check  = false  # Already disabled in dev
```

### Restarting After Budget Auto-Stop

If your instance was stopped due to reaching the $200 budget limit:

```bash
# 1. Review your costs in AWS Cost Explorer
# 2. Adjust budget limits if needed
terraform apply -var="monthly_budget_limit=300"

# 3. Manually restart the instance
aws ec2 start-instances --instance-ids $(terraform output -raw instance_id)

# 4. Wait for BigBlueButton to fully start (2-3 minutes)
# 5. Verify health
curl -k https://YOUR_DOMAIN/bigbluebutton/api
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run linting: `make lint`
4. Submit a pull request

## License

MIT License - see LICENSE file for details.
