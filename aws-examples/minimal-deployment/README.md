# Minimal Infrastructure Deployment

This infrastructure configuration contains the VPC module, its components,
the EKS module, and its components, including a core worker group and a user
worker group. Accepts inputs for the deployment name, `awscli` profile, and
AWS region.

## Deployment

If you want to configure some of the deployment inputs, make a
`.tfvars` file and put in your own values for the contents of
`variables.tf`. When you run `terraform apply` or `terraform destroy`,
you can add `--var-file=<your-values>.tfvars` to pass these values
to Terraform.

To deploy, run:

```
cd minimimal-deployment
terraform init
terraform apply
```

## Tear-Down

If you put anything onto the infrastructure that Terraform created,
such as a Helm release of JupyterHub, remove that before continuing.

To tear down the infrastructure, run:

```
cd minimal-deployment
terraform destroy
```
