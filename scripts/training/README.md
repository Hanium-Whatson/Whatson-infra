# Dev Training Terraform from AWS CloudShell

`dev/training` Terraform can be provisioned from AWS CloudShell with the script in this directory:

```bash
./scripts/training/provision-dev-training-from-cloudshell.sh
```

## Before You Run

1. Clone this repository into CloudShell.
2. Ensure Terraform is installed in CloudShell.
3. Prepare `terraform/environments/dev/training/terraform.tfvars`.

If the file does not exist yet:

```bash
cp terraform/environments/dev/training/terraform.tfvars.example \
  terraform/environments/dev/training/terraform.tfvars
```

## Required Checks in `terraform.tfvars`

Update these values before `apply`:

- `data_lake_bucket_name`
  - S3 bucket names must be globally unique.
  - Example: `whatson-dev-training-<your-name>-20260508`
- `training_entrypoint`
  - Replace the placeholder bootstrap with the actual training startup commands when ready.
- `training_ami_id`
  - Optional. Set this if you want a custom AMI instead of the module default.

Current default file:

- Region: `ap-northeast-2`
- Environment: `dev`
- Training instance type: `g4dn.xlarge`

## How the Script Works

The script:

1. Verifies `terraform` and `aws` are available.
2. Verifies `terraform/environments/dev/training/terraform.tfvars` exists.
3. Runs:
   - `terraform init`
   - `terraform fmt -check`
   - `terraform validate`
   - `terraform plan -var-file=terraform.tfvars -out=tfplan`
   - `terraform apply tfplan`

## Run

From the repository root in AWS CloudShell:

```bash
chmod +x scripts/training/provision-dev-training-from-cloudshell.sh
./scripts/training/provision-dev-training-from-cloudshell.sh
```

## After Apply

Check the outputs:

```bash
cd terraform/environments/dev/training
terraform output
```

Useful values:

- `data_lake_bucket`
- `lambda_functions`
- `training_runner_instance_id`
- `training_runner_public_ip`

## Notes

- The current `dev/training` stack creates the training runner in a public subnet because `training.tf` uses `module.network.public_subnet_ids[0]`.
- The stack currently has one schedule variable exposed in this environment: `crawl_schedule_expression`.
- The script uses the local `terraform.tfvars` file in `terraform/environments/dev/training`.
