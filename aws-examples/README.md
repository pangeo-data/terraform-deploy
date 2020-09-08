# AWS Deployment Examples

This folder houses different deployments to be used as examples.

### `minimal-deployment-tutorial/`

This is meant as the
[Zero-to-JupyterHub-K8s](https://zero-to-jupyterhub.readthedocs.io/en/latest/)
equivalent setup. It's a very short, minimally configured setup that deploys
enough infrastructure to support a JupyterHub deployment. This also heavily
features tutorial documentation and is a presented demo at the ADSA 2020
conference (link to come).

### `blog-post/`

This accompanies the blog post
[Deploying JupyterHub-Ready Infrastructure with Terraform on AWS](https://medium.com/pangeo/terraform-jupyterhub-aws-34f2b725f4fd).
The infrastructure and instructions are present in this folder, but
the blog post gives background information and is written better.

### `hackweek-infrastructure/`

Hackweeks are a large part of the educational branch of UW's
eScience Institute. Here, we have infrastructure that was used to support
two of these hackweeks. It deploys similar infrastructure to the `blog-post`
example, but is more battle-tested.

