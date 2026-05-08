#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform/environments/dev/training"
TF_VARS_FILE="${TF_DIR}/terraform.tfvars"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is not installed. Install Terraform in AWS CloudShell first."
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "aws cli is not installed. AWS CloudShell should include it by default."
  exit 1
fi

if [[ ! -f "${TF_VARS_FILE}" ]]; then
  echo "Missing tfvars file: ${TF_VARS_FILE}"
  echo "Create it from terraform/environments/dev/training/terraform.tfvars.example first."
  exit 1
fi

AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
AWS_REGION="$(aws configure get region || true)"

if [[ -z "${AWS_REGION}" || "${AWS_REGION}" == "None" ]]; then
  AWS_REGION="ap-northeast-2"
fi

echo "Provisioning Terraform for dev/training"
echo "Account: ${AWS_ACCOUNT_ID}"
echo "Region: ${AWS_REGION}"
echo "Terraform directory: ${TF_DIR}"
echo

cd "${TF_DIR}"

terraform init
terraform fmt -check
terraform validate
terraform plan -var-file="${TF_VARS_FILE}" -out=tfplan
terraform apply tfplan

echo
echo "Terraform apply completed."
echo "Useful follow-up commands:"
echo "  cd ${TF_DIR}"
echo "  terraform output"
echo "  terraform output training_runner_public_ip"
