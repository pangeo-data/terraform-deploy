# PANGEO Terraform Deploy

## Introduction

This repo houses an opinionated deployment of PANGEO-style
JupyterHub-ready infrastructure with
[Terraform](https://www.terraform.io/). 

This particular branch is presented for use with the Medium blog post
[Deploying JupyterHub-Ready Infrastructure with Terraform on AWS](https://medium.com/pangeo/terraform-jupyterhub-aws-34f2b725f4fd).
The guide to deploy this JupyterHub-ready infrastructure can be
summarized as:
- Download Terraform, its dependencies, and the repo
- Configure a few settings for the infrastructure and for the AWS CLI
- Deploy the infrastructure using Terraform commands


## Deployment Instructions

### Install Terraform, dependencies, and this GitHub repo

In order to deploy the configuration in this repo, you'll need the
following tools installed:

- [Terraform](https://www.terraform.io/downloads.html)
- [AWS CLI](https://aws.amazon.com/cli/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Helm](https://helm.sh/docs/intro/install/)

You will also need this repo. You can get it with:

```
git clone https://github.com/pangeo-data/terraform-deploy.git
cd terraform-deploy/aws-examples/blog-post/
```

You will notice there are two folders here, `aws` and `aws-creds`.
Terraform will interact with each directory separately. We can now set
up some credentials before we deploy the infrastructure.

### Configuration

#### Configure the AWS CLI

You need to have the `aws` CLI configured to run correctly from your
local machine - terraform will just read from the same source. The
[documentation on configuring AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
should help.

This repo provides the `aws-creds` folder in case you do not have
admin permissions or want to follow the principle of least privilege.
In order to run the Terraform commands in the `aws` folder, we will
use the minimal policy set defined at the bottom of `iam.tf`. By
default (as in, what is uncommented), the folder gives you a new user
named `terraform-bot` with policy attachments for the minimal policy
set and EFS permissions.

If you want to experiment with other ways to enable the policies you
can try! Some of them are present (but commented out) in the same file.

If you want to create this user, go into `aws-creds/iam.tfvars` and
make sure the value of `profile` is the correct awscli profile you
want to use. Then, run the following:

```
cd aws-creds
terraform init
terraform apply -var-file=iam.tfvars
```

Terraform will show the plan to create the IAM policy, an IAM user,
and the attachment of two policies onto the user. Confirm the apply
command and Terraform will let you know when it's finished.

You will then have to configure `terraform-bot`'s credentials in the
AWS Console. Go and generate access keys for the user, then put them
into your command line with 

```
aws configure --profile terraform-bot
```

Later, you will tell Terraform to use this profile when running
commands so that it has only the permissions it needs when deploying
the infrastructure.

#### Configure your Infrastructure

The terraform deployment needs several variable names set before it
can start. If you look in `aws/your-cluster.tfvars`, there are four
variables present. You should input cluster and vpc names. You only
have to change the region if you want to create resources in a
different region. Similarly, the profile only needs to be changed if
you are not using the `terraform-bot` user from the last step. 

You can change the name of this file if you want. Just keep in mind
that the instructions will list it as `<your-cluster>.tfvars` and you
will have to type in the new filename that you set. A professional
deployment should have a more descriptive name, but it isn't necessary
here.

There are additional variables you can specify in your `.tfvars` file
if you wish. The other variables are present in `aws/variables.tf`.

To force Terraform to use the values provided, we will add the flag
`-var-file=<your-cluster>.tfvars` with every Terraform command. 

The final bit of Terraform configuration is run with `terraform init`.
This makes Terraform check all of the files in the working directory
and see if it needs to download anything in order to work properly.
Here, these downloads are module and provider blocks. If you attempt
to run other commands before this, Terraform will prompt you to
initialize the working directory.

Make sure you are in the `aws` folder, then run

```
terraform init
```

### Infrastructure Deployment

NOTE: Creating these resources will cost your AWS account money. This
cluster configuration has cost me under $5 per day running the
cluster, vpc, and core node. 

#### First-Time Deployment

If you have configured the `awscli` profile you want to use and input
the values you like into your `.tfvars` file, then you are ready to
deploy the infrastructure! Running the command below will first
generate a plan as Terraform validates the configuration. The plan is
a list of the lowest-level resources it can give you. We use the
modules so we don't have to look at all the low-level resources all
the time (that's a lot to look at), but it is good to look at them at
least once to make sure you understand everything you are creating.

You can take a look at the 63 resources if you like, but at the end of
the day, all you need to do to start deploying infrastructure is type
`yes` when Terraform prompts you.

```
terraform apply -var-file=<your-cluster>.tfvars
```

The infrastructure can take 15 minutes or more to create (the EKS
cluster takes 9-12 minutes alone).

While watching Terraform deploy everything, you may notice that
sometimes many resources are created at the same time, but other times
only one resource is being created. Terraform takes into account
resource dependencies and will make sure independent resources are
created before dependent ones. It will try to deploy as many things at
once as possible but will have to wait for certain resources to finish
before it can move on.

NOTE: Sometimes you will get an error saying the Kubernetes cluster is
unreachable. This is usually resolved by running the `terraform apply
...` command again.

Tons of green output means the deployment was successful!
Congratulations!

#### Inspecting the Infrastructure

If you want to take a peek at your cluster, you will need to tell
`kubectl` and `Helm` where your cluster is, since Terraform doesn't
modify them by default. Do this with the following command, filling in
values for your deployment.

```
aws eks update-kubeconfig --name=<cluster-name> --region=<region>
--profile=<profile>
```

Now you should be able to run local commands to inspect the cluster!
Try the following:

```
aws eks list-clusters --profile=<profile>
aws eks describe-cluster --name=<cluster-name> --profile=terraform-bot
kubectl get pods -A
kubectl get nodes -A
helm list -A
```

You should be able to see
- A list of clusters on your account, including the one you just made
- Information about the cluster you just made
- All of the pods (individual software) present on machines in the
cluster
- All of the nodes (actual machines) in the cluster, which should just
be one core node
- All of the Helm releases on the cluster, which should be the
`efs-provisioner` and the `cluster-autoscaler`.

If there were problems with deployment, these commands might fail or
give you insight into the problems.

#### Modifying the Infrastructure

NOTE: Do not modify AWS resources with the console if you created them
with Terraform. This can cause unintended problems for Terraform
because it can't see the resource changes you made.

If you want to change some of the values or infrastructure, you can
fiddle with the `.tf` files and then run `terraform apply
-var-file=<your-cluster>.tfvars` again. Terraform will compare the new
plan to the old plan that you already deployed and see what is has to
do to get from one to the other. For individual resources, this may be
an easy in-place modification, others may have to be destroyed and
re-created, and others still may just be different resources, so you
delete them and make the replacements. Terraform takes care of all of
this for you but will show you what it intends to do in the plan it
outputs.

NOTE: If you change the worker group templates and there are existing
nodes when you run `terraform apply ...`, it wil not apply the changes
to existing nodes. You will have to manually drain the node by setting
the desired number of nodes to 0 in the AWS Console, wait for the
nodes to disappear, then set the desired number of nodes to 1 once
`terraform apply ...` has finished.

NOTE: Changing the desired number of nodes after the worker group
template has been created will not work unless you do so in the AWS
Console. Terraform doesn't affect that after the worker group template
has been created.

#### Tear Down

If you don't want these resources on your account forever (since they
cost you money), you can tear it all down with one command per
directory.

Terraform remembers everything it has currently built, so as long as
you provide the `.tfvars` file, it will find the resources correctly
and remove them in the reverse order that they were built!

Running `terraform destroy ...` will generate a plan similar to
`terraform apply ...`, but it will indicate that it is deleting
resources, not deploying them. Again, you will be prompted to confirm
the plan by typing `yes`.

```
terraform destroy --var-file=<your-cluster>.tfvars
```

The `destroy` command can time out trying to destroy some of the
Kubernetes resources, but re-running it usually solves the issue. If
you put anything on your cluster (besides the `efs-provisioner` and
the `cluster-autoscaler`), you should remove it before running
`terraform destroy ...`. Since Terraform isn't detecting what software
is on your cluster (it only knows what it put on the cluster), it
doesn't know how to remove it, and that can lead to issues.

Removing the `terraform-bot` user will require to manually delete the
access keys in the AWS Console. Then, you can delete the Terraform
entries.

```
cd ../aws-creds/
terraform destroy -var-file=iam.tfvars
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

If you had a previous `kubectl` context set, you may also want to set
it to be something else with

```
kubectl config use-context <different context>
```
