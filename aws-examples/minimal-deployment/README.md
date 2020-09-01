# Minimal Infrastructure Deployment

This configuration deploys infrastructure that can support a
JupyterHub. We use Terraform to deploy it on AWS.

## Infrastructure

This example is a minimally-configured deployment of:
- VPC using private subnets behind public subnets and networking
- EKS cluster with two worker groups, core and user.

This configuration utilizes a Terraform module for each of these,
enabling minimal configuration for us without sacrificing security
and completeness.

A JupyterHub can be deployed onto this infrastructure, though it
is not recommended for much more than testing.

## Deployment

Deployment expects that you have AWS credentials with all the necessary
permissions. Permissions are present for other examples or the main
repo, but are not shown here. The easiest option is if you have admin
privileges on your AWS account.

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

## Next Steps

If you want to interact with the cluster after it is created, you will
need to configure `kubectl`. Do this with:

```
aws eks update-kubeconfig --name=<your-cluster> --profile=<your-profile>
```

You should now be able to use `helm` and `kubectl` commands to deploy
software onto the cluster. 


## Tear-Down

If you put anything onto the infrastructure that Terraform created,
such as a Helm release of JupyterHub, remove that before continuing.

To tear down the infrastructure, run:

```
cd minimal-deployment
terraform destroy
```

If you set your local kubeconfig to point to this cluster, you can
remove that with the following:

```
kubectl config delete-cluster <your-cluster-arn>
kubectl config delete-context <your-cluster-context>
kubectl config unset users.<user-name>
```

You can get those variables with the corresponding commands:

- `your-cluster-arn`: `kubectl config get-clusters`
- `your-cluster-context`: `kubectl config get-contexts`
- `user-name`: `kubectl config view`, the name you want will look
something like
`arn:aws:eks:us-west-2:############:cluster/<your-cluster>`.

If you had a previous `kubectl` context set, you may also want to set it to be something else with

```
kubectl config use-context <different context>
```
