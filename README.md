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
can start. You can copy the file `aws/template.tfvars` into a file
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

#### 5. Test out your hub!

Once Step 4 finishes, you should find the public endpoint of the hub
that was just set up.

a. Based on the variables you set in your `tfvars` file, run this command

   ```
   aws eks update-kubeconfig --region=<your-region> --name=<your-cluster>
   ```

   This should connect `kubectl` to the kubernetes cluster we just built.
b. You can find the JupyterHub's public URL with

   ```
   kubectl -n staging get svc proxy-public
   ```

c. Copy the long URL under 'EXTERNAL-IP' into your browser. Login with
   any username and password, and check out your new hub!
