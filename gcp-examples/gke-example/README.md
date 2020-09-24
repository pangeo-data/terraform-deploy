# Google Cloud VM Example

Deploy a network and a GKE cluster on Google Cloud via
Terraform.

## Setup

Download / Configure the following

- [Terraform](https://www.terraform.io/downloads.html)
- gcloud:
  - [Install](https://cloud.google.com/sdk/docs/install)
  - [Configure](https://cloud.google.com/sdk/docs/initializing)
  - Create and download a
  [service account key](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) 

## Deployment

Input variables into `your-cluster.tfvars` if you want
options that differ from the defaults in `variables.tf`.
Using these variables will require adding the following flag
to all `terraform` commands: `--var-file=your-cluster.tfvars`.

In particular, you will need to supply the filepath of your
service account key to the `credential_file` input variable.

And yes, you need both the `google` and the `google-beta`
providers.

Once you are ready to deploy, you can look at the plan with:

```
terraform plan
```

Deploy the network and cluster with:

```
terraform apply
```

## Tear Down

Remove the network and cluster with:

```
terraform destroy
```
