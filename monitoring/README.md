## Monitoring for JupyterHubs

The standard monitoring tools in the JupyterHub community are Prometheus and Grafana. Prometheus collects data about the cluster and stores it locally while Grafana takes this data and allows you to create visualizations and dashboards. 

### Usage

This module is used to setup the cluster settings necessary for Prometheus and Grafana to work. .yaml files are provided for each software, as is configuration for Prometheus's storageClass in k8s.

#### Configuration

Available inputs are in `variables.tf`. Set them if needed.

#### Outputs

None yet. Probably should include some.

#### TODO

a. Enable changing of grafana admin's username and password. These are present in `grafana-values.yaml`.
b. Enable secrets, probably mostly to mask the grafana admin's username and password.