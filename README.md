# PANGEO Terraform Deploy

Opinionated deployment of a PANGEO-style JupyterHub with [Terraform](https://www.terraform.io/)

## What?

A cloud based JupyterHub close to your data is a great way to run interactive
computations, especially paired with [Dask](http://dask.org/) for parallel compute.
However, setting these up on your cloud provider of choice in an automated fashion
with reasonable defaults can be a chore. This project aims to automate as much of that
as possible.

This project's goal is to help you set up and maintain this kind of environment
in a completely automated fashion - including setting up all the cloud infrastructure
necessary. We do this by leveraging open source projects like
[terraform](https://www.terraform.io/), [helm](https://helm.sh/) and
[zero-to-jupyterhub](https://z2jh.jupyter.org).

Currently, there is only code for AWS here. However, we hope other cloud providers
will be represented here soon enough.

## How?

### AWS Setup

#### 1. Install Tools

You'll need the following tools installed:

1. [Terraform](https://www.terraform.io/downloads.html).
   If you are on MacOS, you can install it with `brew install terraform`
2. [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
   If you are on MacOS, you can install it with `brew install kubectl`
3. [AWS CLI](https://aws.amazon.com/cli/)

#### 2. Authenticate to AWS

You need to have the `aws` CLI configured to run correctly from your
local machine - terraform will just read from the same source. The
[documentation on configuring AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
should help.

#### 3. Fill in your variable names

The terraform deployment needs several variable names set before it
can start. You can copy the file `aws/your-cluster.tfvars.template` into a file
named `aws/<your-cluster>.tfvars`, and modify the placeholders there
as appropriate.

#### 4. Run terraform!

Once this is all done, you should:

a. `cd aws`
b. Run `terraform init` to set up appropriate plugins
c. Run `terraform apply -var-file=<your-cluster>.tfvars`, referring to
   The `tfvars` file you made in step 3
d. Type `yes` when prompted
e. ![Wait for a while](https://imgs.xkcd.com/comics/compiling.png).
   This could take a while!

Your cluster is now set up! There are no hubs on it yet though. You should
make a copy of the [hubploy template](https://github.com/yuvipanda/hubploy-template)
repo, and go from there.
