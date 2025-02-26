# References -  Deployment Automation for BigBlueButton Conferencing on AWS

## Articles
* [AWS Blog - Open Source Web Conferencing Solution on AWS](https://aws.amazon.com/blogs/opensource/deploying-an-open-source-web-conferencing-solution-bigbluebutton-on-aws/)
* [AWS Blog - Build Scalable BBB on AWS](https://aws.amazon.com/blogs/opensource/how-to-build-a-scalable-bigbluebutton-video-conference-solution-on-aws/)
* [Scaleway - Building BBB](https://www.scaleway.com/en/blog/building-bigbluebutton-powered-by-scaleway/)
* [BBB Install Script](https://github.com/bigbluebutton/bbb-install)
* [Create Github Actions IAM Role](https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/)

## AWS
* [AWS - EC2 Device Names for Volumes ](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html) - start at /dev/sdf

## Terraform
* [Terraform Bootstrap TFState Backend on AWS](https://github.com/cloudposse/terraform-aws-tfstate-backend)
* [Terraform Path Module](https://developer.hashicorp.com/terraform/language/expressions/references)

## GitHub Actions
* [Configure AWS Credentials for GitHub Actions](https://github.com/aws-actions/configure-aws-credentials)
* [GitHub Actions - Using Secrets](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions)
* [Blog - Set up a Terraform Pipeline with GitHub Actions and GitHub OIDC for AWS](https://blog.symops.com/post/terraform-pipeline-with-github-actions-and-github-oidc-for-aws)
* [AWS GitHub Actions OIDC Terraform Module](https://github.com/unfunco/terraform-aws-oidc-github)

* [Using ACT to test GitHub Actions locally](https://github.com/nektos/act)
* [Beyond Fireship - How GitHub Actions 10x my productivity](https://www.youtube.com/watch?v=yfBtjLxn_6k)
* [Setup-Terraform - Javascript Action for setting up Terraform CLI for Github Actions workflow](https://github.com/hashicorp/setup-terraform)

* [GitHub Actions - Creating a Composite Action](https://docs.github.com/en/actions/sharing-automations/creating-actions/creating-a-composite-action)
* [Creating pre-written blocks in workflow](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/using-pre-written-building-blocks-in-your-workflow)
* [Metadata syntax for GitHub Actions](https://docs.github.com/en/actions/sharing-automations/creating-actions/metadata-syntax-for-github-actions)

## Dev Testing

Set the following environment variables:

```
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_REGION=""
```

## Troubleshooting

* If you are using GitHub Actions to bootstrap the Terraform state/lock files, make sure that you enable the ability for GitHub Actions to create and approve Pull requests. [Reference](https://stackoverflow.com/questions/72376229/github-actions-is-not-permitted-to-create-or-approve-pull-requests-createpullre)

.