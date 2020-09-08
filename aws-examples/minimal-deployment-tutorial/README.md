# Minimal Deployment Tutorial

This example is meant as a small tutorial to Terraform. It is a very
high-level overview of some of the concepts and should not replace
[Terraform's tutorials](https://learn.hashicorp.com/collections/terraform/aws-get-started).
A lot of the content in this README is paraphrased from
Terraform's documentation.

## Why Terraform?

Terraform is a tool we use to deploy cloud infrastructure. This infrastructure
can be as simple as a single computer in the cloud or as complex as hundreds
of machines spinning up on demand for high-performance computing.

![Terraform deployment diagram](https://github.com/salvis2/terraform-deploy/blob/master/terraform-aws-vpc-eks-deployment.png?raw=true)

Shown above is an example deployment - the second example in this tutorial.
The network is set up, a cluster deployed into it, and a JupyterHub can
be put into the cluster. A more complex version of this was deployed for
40-60 user hackweeks. You can find that in 
`aws-examples/hackweek-infrastructure/`.

Each cloud provider has their own user interface you can access on the web and
command-line tool for more programmatic access. However, we prefer Terraform
for two main reasons: 

1. Terraform is cloud-agnostic. If you know how to use Terraform to deploy AWS
cloud infrastructure, you know how to use Terraform to deploy GCP cloud
infrastructure. You can use it to deploy on many of the main cloud providers
without changing tools, which lowers the barrier to trying out different
clouds.

2. Terraform gracefully tracks what it has created. This means that running
the same commands multiple times does not cause errors or change the end
result unless an incremental change is provided. Terraform looks at the
difference between what you have deployed and what you want to deploy, then
deploys only what it needs to. Tearing down your infrastructure is equally
simple and you won't miss removing anything as long as everything you
deployed was deployed with Terraform.

## Prerequisites

Before running any commands for this example, you should install a few things:

- [Terraform](https://www.terraform.io/downloads.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Helm](https://helm.sh/docs/intro/install/)
- [AWS CLI](https://aws.amazon.com/cli/): As part of installing this, you
will need to make an AWS account if you don't have one and
[configure](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)
`awscli` to use that account.

You can then clone this repo:

```
git clone https://github.com/pangeo-data/terraform-deploy.git
cd terraform-deploy/aws-examples/minimal-deployment/
```

## EC2 Example / Intro to Terraform

As a way to introduce some of the Terraform concepts, we will first deploy
an Elastic Compute Cloud (EC2) instance, a single machine in AWS's cloud. The
configuration for this section is in `ec2-intro-tutorial/`. 

### Infrastructure

The infrastructure is just an EC2 instance. 

### Terraform Components

#### Providers

Providers are there to understand resources and API interactions for a
given infrastructure platform. Here, we have the AWS provider to enable
us to create AWS infrastructure.

#### Input Variables

Input variables act as parameters, giving a way for users to customize a
deployment without altering the configuration code. This also enables users
to share configurations with others more easily. Variables are defined in
`ec2-intro-tutorial/ec2-variables.tf` and can be overridden in
`ec2-intro-tutorial/your-ec2-values.tfvars`.

#### Data Sources

Data sources fetch and compute data for use in Terraform's configuration. We
have a data source here to find an Amazon Machine Image ID that we use for
our EC2 instance.

#### Resources

Resources describe one or more infrastructure objects. Our only resource here
is the EC2 instance, seen in `ec2-intro-tutorial/ec2-main.tf`.

#### Output Values

Output values are the equivalent of return values. We use them here to print
relevant information about the deployment once it is deployed, such as the
AMI ID we used and the Amazon Resource Name (ARN) of our EC2 instance.
Output values are defined for this folder in `ec2-intro-tutorial/ec2-outputs.tf`.
Every data source and resource block also has outputs (see below).

#### Variable Referencing

Terraform adds functionality by allowing programmatic references
to resources' and data sources' outputs. We use this here to set the
AMI for the EC2 instance to be the value that our data source found.
Also, the name of the EC2 instance is the input variable `deployment_name`.

### Deployment

Deployment expects that you have AWS credentials with all the necessary
permissions. Permissions are present for other examples or the main
repo, but are not shown here. The easiest option is if you have admin
privileges on your AWS account.

#### Set Up Input Variables

Input variables are defined in `ec2-intro-tutorial/ec2-variables.tf`. Their
values can be overwritten by specifying entries in
`ec2-intro-tutorial/your-ec2-values.tfvars`. When you run a plan, apply, or
destroy command, you can supply these values to Terraform with
`--var-file=your-ec2-values.tfvars`.

#### Command: Plan

The `terraform plan` command creates and shows Terraform's execution plan.
If you have not deployed anything yet, this will be all the resources
Terraform plans to deploy. If you have deployed some resources, this plan
will show what Terraform needs to deploy or change to get to the new
configuration. If you have deployed everything, the plan will indicate
that everything is up-to-date.

To look at the execution plan, run:

```
cd ec2-intro-tutorial/
terraform init
terraform plan --var-file=your-ec2-values.tfvars
```

#### Command: Apply

The `terraform apply` command applies the changes to get to the desired
configuration state. This behavior is similar to the plan command. 
Every time you run `terraform apply`, the plan will be displayed before
prompting you to accept the actions.

To deploy the configuration, run:

```
cd ec2-intro-tutorial/
terraform init
terraform apply --var-file=your-ec2-values.tfvars
```

The first two lines are unecessary if you ran them in the Command: Plan
section.

### Next Steps

If you want to connect to this EC2 instance, there are two options:

1. Connect to it through the EC2 console. AWS Documentation says:
> You can connect using EC2 Instance Connect with just a valid username. You
can connect using Session Manager if you have been granted the necessary
permissions. I have had some difficulties doing this, though.

2. Create a key pair in the AWS console. You will then have to associate it
with your EC2 instance, see more on that in the
[Terraform documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#key_name).
If you create the key pair, you will need to use the AWS console to delete it.
Terraform does not manage the key pair for you.

### Tear-Down

When you are ready to tear down the EC2 example, run:

```
terraform destroy --var-file=your-ec2-values.tfvars
```

and type `yes` when prompted.

## Simple Cluster Deployment

This configuration deploys infrastructure that can support a
JupyterHub, though itis not recommended for much more than testing.
We use Terraform to deploy it on AWS.

![Terraform deployment diagram](https://github.com/salvis2/terraform-deploy/blob/master/terraform-aws-vpc-eks-deployment.png?raw=true)

Here is a visualization of the infrastructure that we will deploy, also
seen above.

### Infrastructure

This example is a minimally-configured deployment of:
- A Virtual Private Cloud (VPC), essentially the network in the cloud that
the cluster lives in. Security is a high priority on this.
- An Elastic Kubernetes Service (EKS) cluster, with one machine for the core
JupyterHub services and one for the users.

This configuration utilizes a Terraform module for each of these,
enabling minimal configuration for us without sacrificing security
and completeness.

### Terraform Components

#### Modules

In addition to the components used in the previous examples, we have modules.
Modules are collections of resources that are used together. They enable us to
focus on the high-level decisions and leave the harder parts of infrastructure
to the people that have made the module.

Both modules require the AWS provider and the EKS module requires several
others, listed in `main.tf`. 

Both modules also have outputs. Some are referenced in `outputs.tf` and others
are variable references between modules! The line

```
  vpc_id          = module.vpc.vpc_id
```

in `main.tf` takes in an output of the VPC module and uses it as an input
for the EKS module. This also helps Terraform realize there is a resource
dependency, so it will create the VPC resources before the EKS ones.

The VPC and EKS cluster are both deployed using modules that were developed
by the Terraform open-source community!

### Deployment

Deployment expects that you have AWS credentials with all the necessary
permissions. Permissions are present for other examples or the main
repo, but are not shown here. The easiest option is if you have admin
privileges on your AWS account.

Input variables are defined in `variables.tf`. Their values can be
overwritten by specifying entries in `your-cluster.tfvars`. When you run a
plan, apply, or destroy command, you can supply these values to Terraform with
`--var-file=your-cluster.tfvars`.

To deploy, run:

```
cd minimimal-deployment
terraform init
terraform apply --var-file=your-cluster.tfvars
```

And type `yes` when prompted.

There should be 41 resources that need to be created. The
infrastructure creation process can take 15+ minutes, mostly because of
the EKS cluster. The infrastructure will cost a few dollars a day to keep
it up, so keep that in mind.

### Next Steps

If you want to interact with the cluster after it is created, you will
need to configure `kubectl`. Do this with:

```
aws eks update-kubeconfig --name=<your-cluster> --profile=<your-profile>
```

You should now be able to use `kubectl` and `helm` commands to inspect
the cluster or deploy software onto it.

### Tear-Down

If you put anything onto the infrastructure that Terraform created,
such as a Helm release of JupyterHub, remove that before continuing.

To tear down the infrastructure, run:

```
cd minimal-deployment
terraform destroy --var-file=your-cluster.tfvars
```

and type `yes` when prompted.

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

If you had a previous `kubectl` context set, you may also want to set it to
be something else with

```
kubectl config use-context <different context>
```

## Wrap-Up

In this tutorial, we learned what Terraform is and why it is useful. After
learning the basics, we deployed and tore down a single machine in AWS's
cloud, then a scalable cluster of machines! I hope you learned something
useful.

Feel free to get involved in this repo or ask me, Sebastian Alvis (@salvis2)
for more information.

