#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform/environments/dev/training"
TF_VARS_FILE="${TF_DIR}/terraform.tfvars"
TF_PLAN_FILE="${TF_DIR}/tfplan"

get_region_from_imds() {
  local token
  local identity_document

  token="$(curl -fsS -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 60" || true)"

  if [[ -n "${token}" ]]; then
    identity_document="$(curl -fsS \
      -H "X-aws-ec2-metadata-token: ${token}" \
      "http://169.254.169.254/latest/dynamic/instance-identity/document" || true)"
  else
    identity_document="$(curl -fsS \
      "http://169.254.169.254/latest/dynamic/instance-identity/document" || true)"
  fi

  if [[ -n "${identity_document}" ]]; then
    echo "${identity_document}" | sed -n 's/.*"region"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
  fi
}

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is not installed on this EC2 host."
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "aws cli is not installed on this EC2 host."
  exit 1
fi

if [[ ! -f "${TF_VARS_FILE}" ]]; then
  echo "Missing tfvars file: ${TF_VARS_FILE}"
  echo "Create it from terraform/environments/dev/training/terraform.tfvars.example first."
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required to detect the EC2 region from instance metadata when AWS region is unset."
  exit 1
fi

AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"

if [[ -z "${AWS_REGION}" || "${AWS_REGION}" == "None" ]]; then
  AWS_REGION="$(aws configure get region 2>/dev/null || true)"
fi

if [[ -z "${AWS_REGION}" || "${AWS_REGION}" == "None" ]]; then
  AWS_REGION="$(get_region_from_imds)"
fi

if [[ -z "${AWS_REGION}" || "${AWS_REGION}" == "None" ]]; then
  AWS_REGION="ap-northeast-2"
fi

export AWS_REGION
export AWS_DEFAULT_REGION="${AWS_REGION}"

AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

echo "Provisioning Terraform for dev/training"
echo "Account: ${AWS_ACCOUNT_ID}"
echo "Region: ${AWS_REGION}"
echo "Terraform directory: ${TF_DIR}"
echo

cd "${TF_DIR}"

rm -f "${TF_PLAN_FILE}"

terraform init -input=false
terraform fmt -check
terraform validate
terraform plan -input=false -var-file="${TF_VARS_FILE}" -out="${TF_PLAN_FILE}"
terraform apply -input=false "${TF_PLAN_FILE}"

echo
echo "Terraform apply completed."
echo "Useful follow-up commands:"
echo "  cd ${TF_DIR}"
echo "  terraform output"
echo "  terraform output training_runner_public_ip"
