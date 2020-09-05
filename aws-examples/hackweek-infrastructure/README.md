# Hackweek Example Infrastructure

This is an example infrastructure configuration that can support a
JupyterHub for the purpose of a hackweek. Two hackweeks have been
supported in this manner. Each of them has a repo for its infrastructure:
- [ICESat-2 Hackweek 2020](https://github.com/ICESAT-2HackWeek/terraform-deploy/tree/master)
- [OceanHackWeek 2020](https://github.com/oceanhackweek/ohw-terraform-deploy/tree/main)

This repository has been used with the
[hackweek-template](https://github.com/salvis2/hackweek-template)
repository, which deploys the JupyterHub onto the cluster using
[`hubploy`](https://github.com/yuvipanda/hubploy). The instructions for
deploying the JupyterHub are present in the `hackweek-template` repo.

This repo has three folders, each of which serves a specific purpose:
- `s3-backend/`: Set up an S3 bucket to hold Terraform's configuration
for the other two folders. 
- `iam-permissions/`: Set up an IAM user to have all of the permissions
Terraform needs to deploy this infrastructure.
- `infrastructure/`: The infrastructure's configuration.

## S3 Backend

The backend is optional. If you are managing the infrastructure alone,
you probably don't need a backend. If this is the case, you can delete
the `backend` blocks in `infrastructure/main.tf` and
`iam-permissions/iam.tf`.

If you are working with multiple people to manage the infrastructure,
it is highly recommended to have a backend. Terraform only understands
what it has deployed because of its state file. The backend stores the
state file encrypted on S3, allowing multiple people to work on the
configuration without having to check Terraform state files into version
control. Since the state file contains all secrets in plain text,
checking it into version control would immediately release all your
secrets to the internet. Don't do it.

If you need to change some of the variables in `s3-backend/variables.tf`,
you can make a `.tfvars` files with some new values. If you do this,
put the `--var-file=<your-values>.tfvars` flag after any
`terraform plan`, `terraform apply`, or `terraform destroy` command.

Build the backend with Terraform:

```
cd s3-backend
terraform init
terraform apply
```

## IAM Permissions

This section is also optional. If you have an IAM profile with `admin`
privileges, you can use your own AWS profile. You will need to supply
this profile name in `infrastructure/<your-values>.tfvars`.

If you changed the S3 backend bucket's name, change it in the `backend`
block in `iam-permissions/iam.tf`. It must be hard-coded, so passing
a variable to this key is not possible.

Create the user with:

```
cd iam-permissions
terraform init
terraform apply
```

You will then have to manually create keys for this user in the
[IAM section of the AWS Console](https://console.aws.amazon.com/iam/).
Configure `awscli` to use these keys with
`aws configure --profile=<var.new-user-name>`.

If you add infrastructure to the `infrastructure` folder, you may need
to add permissions to this user in order for Terraform to run. You
can rerun the above commands again to update the user's permissions.

## Infrastructure

The infrastructure has the following pieces:
- VPC configured to use private subnets behind public subnets and
routing.
- EKS Cluster with 3 nodegroups, configured for spot instances
and autoscaling.
- `cluster-autoscaler` release to enable autoscaling.
- `aws-node-termination-handler` release for increased quality-of-life
with spot instancing.
- EFS for user home directory storage, hub shared storage, and
read-only storage.
- Bastion machine to connect to the EFS (especially for putting data
into the read-only storage).
- S3 data bucket for hub shared storage.
- Monitoring deployment of Prometheus and Grafana.

Replacing variable values is recommended, so
`your-cluster.tfvars.template` is provided to show the options. You
should copy the content of this file to a new file,
`<your-cluster>.tfvars`, and input your values. Putting more entries
into `map_users` will allow multiple `aws` users to configure the
cluster. 

Replacing the Grafana `adminUser` and `adminPassword` are
highly recommended, but the `.tfvars` files with their values
should **NOT** be checked into version control without encryption.

If you have multiple `.tfvars` files, you can supply them to
Terraform with extra `--var-file` flags, one per `.tfvars` file.

Deploy the infrastructure with:

```
cd infrastructure
terraform init
terraform apply --var-file=<your-cluster>.tfvars
```

This can take 10-15 minutes to create. Sometimes, `helm` resources can
stall out. You should be able to run the `apply` command again and get
it to succeed. You can now put other things on the cluster, like a
JupyterHub!

## Tear-Down

Remove the infrastructure in the reverse order that you created it.
Before doing anything with Terraform, you must remove anything you put
onto the cluster that you didn't put there with Terraform.

Remove infrastructure:

```
cd infrastructure
terraform destroy --var-file=<your-cluster>.tfvars
# wait

cd iam-permissions
terraform destroy

cd s3-backend
terraform destroy
```
