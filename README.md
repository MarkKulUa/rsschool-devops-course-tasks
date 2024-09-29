# Infrastructure Setup and Usage Guide

This README provides a step-by-step guide to setting up AWS infrastructure using Terraform, configuring GitHub Actions for CI/CD, and managing AWS IAM roles and permissions.

## Table of Contents

1. [Step 1: Installing AWS CLI and Terraform](#step-1-installing-aws-cli-and-terraform)
2. [Step 2: Creating an IAM User and Configuring MFA](#step-2-creating-an-iam-user-and-configuring-mfa)
3. [Step 3: AWS CLI Configuration](#step-3-aws-cli-configuration)
4. [Step 4: Creating a GitHub Repository for Terraform Code](#step-4-creating-a-github-repository-for-terraform-code)
5. [Step 5: Creating an S3 Bucket for Terraform State](#step-5-creating-an-s3-bucket-for-terraform-state)
6. [Step 6: Creating an IAM Role for GitHub Actions](#step-6-creating-an-iam-role-for-github-actions)
7. [Step 7: Setting Up Identity Provider and Trust Policies for GitHub Actions](#step-7-setting-up-identity-provider-and-trust-policies-for-github-actions)
8. [Step 8: Creating a GitHub Actions Workflow for Terraform Deployment](#step-8-creating-a-github-actions-workflow-for-terraform-deployment)
9. [Verification and Completion](#verification-and-completion)

## Step 1: Installing AWS CLI and Terraform

### Installing AWS CLI 2

To get started, first install the AWS CLI:

1. Update the list of packages:
   ```bash
   sudo apt update
   ```
2. Install required dependencies:
   ```bash
   sudo apt install unzip curl -y
   ```
3. Download the latest version of AWS CLI:
   ```bash
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   ```
4. Unzip the archive:
   ```bash
   unzip awscliv2.zip
   ```
5. Install AWS CLI:
   ```bash
   sudo ./aws/install
   ```
6. Verify the installation:
   ```bash
   aws --version
   ```

### Installing Terraform 1.6+

Terraform will be used for infrastructure management:

1. Install the HashiCorp GPG key:
   ```bash
   curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
   ```
2. Add the HashiCorp repository:
   ```bash
   sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
   ```
3. Update packages and install Terraform:
   ```bash
   sudo apt update && sudo apt install terraform
   ```
4. Verify the installation:
   ```bash
   terraform version
   ```

### Installing tfenv for Managing Terraform Versions

To easily manage multiple Terraform versions:

1. Clone the tfenv repository:
   ```bash
   git clone https://github.com/tfutils/tfenv.git ~/.tfenv
   ```
2. Add tfenv to your PATH:
   ```bash
   echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```
3. Install Terraform 1.6.0:
   ```bash
   tfenv install 1.6.0
   tfenv use 1.6.0
   ```

## Step 2: Creating an IAM User and Configuring MFA

1. **Sign in** to the AWS console.
2. Navigate to **IAM**.
3. **Create a new IAM user**:
    - Click **Users** > **Add users**.
    - Username: `terraform-user`
    - Access type: **Programmatic access**.
4. **Attach Policies**:
    - Attach the following policies:
        - `AmazonEC2FullAccess`
        - `AmazonRoute53FullAccess`
        - `AmazonS3FullAccess`
        - `IAMFullAccess`
        - `AmazonVPCFullAccess`
        - `AmazonSQSFullAccess`
        - `AmazonEventBridgeFullAccess`
5. Save **Access Key ID** and **Secret Access Key**.
6. Set up **MFA** for the new user using Google Authenticator or similar.

## Step 3: AWS CLI Configuration

Configure AWS CLI for future use:

1. Run the configuration command:
   ```bash
   aws configure
   ```
2. Enter the following:
    - **AWS Access Key ID**: (Access Key ID)
    - **AWS Secret Access Key**: (Secret Access Key)
    - **Default region name**: e.g., `us-east-1`
    - **Default output format**: `json`
3. Verify the setup:
   ```bash
   aws ec2 describe-instance-types --instance-types t4g.nano
   ```

## Step 4: Creating a GitHub Repository for Terraform Code

1. Log in to **GitHub**.
2. Create a new repository named `rsschool-devops-course-tasks`.
3. Clone the repository locally:
   ```bash
   git clone https://github.com/your_username/rsschool-devops-course-tasks.git
   ```

## Step 5: Creating an S3 Bucket for Terraform State

1. Create a `main.tf` file in the repository with the following content:

   ```hcl
   provider "aws" {
     region = "us-east-1"
   }

   resource "aws_s3_bucket" "terraform_state" {
     bucket = "your-unique-terraform-state-bucket-name"
     acl    = "private"

     versioning {
       enabled = true
     }

     server_side_encryption_configuration {
       rule {
         apply_server_side_encryption_by_default {
           sse_algorithm = "AES256"
         }
       }
     }

     tags = {
       Name        = "Terraform State Bucket"
       Environment = "Dev"
     }
   }
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Review and apply the configuration:
   ```bash
   terraform plan
   terraform apply
   ```

## Step 6: Creating an IAM Role for GitHub Actions

1. Create an `iam.tf` file with the following content:

   ```hcl
   resource "aws_iam_role" "GithubActionsRole" {
     name = "GithubActionsRole"

     assume_role_policy = <<EOF
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:your_username/rsschool-devops-course-tasks:*"
           }
         }
       }
     ]
   }
   EOF
   }

   resource "aws_iam_role_policy_attachment" "GithubActionsRolePolicies" {
     for_each = toset([
       "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
       "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",
       "arn:aws:iam::aws:policy/AmazonS3FullAccess",
       "arn:aws:iam::aws:policy/IAMFullAccess",
       "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
       "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
       "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess",
     ])

     role       = aws_iam_role.GithubActionsRole.name
     policy_arn = each.value
   }
   ```

2. Add the AWS account ID to your configuration:
   ```hcl
   data "aws_caller_identity" "current" {}
   ```
3. Create the OIDC provider:
   ```hcl
   resource "aws_iam_openid_connect_provider" "GitHubProvider" {
     url = "https://token.actions.githubusercontent.com"
     client_id_list = ["sts.amazonaws.com"]
     thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
   }
   ```
4. Update and apply Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Step 7: Setting Up Identity Provider and Trust Policies for GitHub Actions

This step is already completed by creating the `assume_role_policy` and OIDC provider in the previous step.

## Step 8: Creating a GitHub Actions Workflow for Terraform Deployment

1. Create the directory `.github/workflows` in your repository.
2. Create a file `terraform.yml` with the following content:

   ```yaml
   name: Terraform CI/CD

   on:
     push:
       branches: [main]
     pull_request:
       branches: [main]

   jobs:
     terraform-fmt:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - name: Terraform Format Check
           uses: hashicorp/setup-terraform@v2
           with:
             terraform_version: 1.6.0
         - name: Terraform Fmt
           run: terraform fmt -check -recursive

     terraform-plan:
       needs: terraform-fmt
       runs-on: ubuntu-latest
       steps:


         - uses: actions/checkout@v3
         - name: Setup Terraform
           uses: hashicorp/setup-terraform@v2
           with:
             terraform_version: 1.6.0
         - name: Terraform Init
           run: terraform init
         - name: Terraform Plan
           run: terraform plan

     terraform-apply:
       needs: terraform-plan
       if: github.ref == 'refs/heads/main' && github.event_name == 'push'
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - name: Configure AWS Credentials
           uses: aws-actions/configure-aws-credentials@v2
           with:
             role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/GithubActionsRole
             aws-region: us-east-1
         - name: Setup Terraform
           uses: hashicorp/setup-terraform@v2
           with:
             terraform_version: 1.6.0
         - name: Terraform Init
           run: terraform init
         - name: Terraform Apply
           run: terraform apply -auto-approve
   ```

3. Add repository secrets:
    - Navigate to **Settings** > **Secrets and variables** > **Actions** > **New repository secret**.
    - Add a secret named `AWS_ACCOUNT_ID` with your AWS Account ID.

4. Commit and push the workflow:
   ```bash
   git add .
   git commit -m "Setup Terraform and GitHub Actions"
   git push origin main
   ```

```markdown
## Verification and Final Steps

### Verifying Terraform Setup

To ensure that everything is correctly set up:

1. Run Terraform plan to check for configuration issues:
   ```bash
   terraform plan
   ```
This command should execute without errors, displaying a summary of the infrastructure changes Terraform will apply.

2. Confirm AWS CLI is properly configured by running an example command:
   ```bash
   aws ec2 describe-instance-types --instance-types t4g.nano
   ```
   If successful, this will output information about the specified instance type, indicating your AWS credentials are working correctly.

### GitHub Actions Workflow Check

1. Push any changes to the `main` branch:
   ```bash
   git add .
   git commit -m "Verify infrastructure setup"
   git push origin main
   ```
   GitHub Actions should automatically trigger the CI/CD workflow for Terraform. Check the workflow status in the **Actions** tab of your GitHub repository.

2. Verify that the Terraform Apply step completes successfully, indicating the infrastructure is applied as intended.


### Summary

- **AWS CLI and Terraform** are successfully installed and configured.
- **IAM User and MFA** are set up for security.
- **Terraform Code** is pushed to **GitHub** with a linked Actions workflow for CI/CD.
- **S3 Bucket** for Terraform state is successfully created and configured.
