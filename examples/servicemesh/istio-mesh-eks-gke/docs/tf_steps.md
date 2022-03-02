

### Provision Clusters
```bash
cd terraform/examples/mc_mesh/clusters

# update variables.tf as required

terraform init
terraform plan
terraform apply

cd - 
```

### Configure Istio

```bash
cd terraform/examples/mc_mesh/istio

terraform init
terraform plan
terraform apply

cd - 
```

### Configure Istio mesh

```bash
cd terraform/examples/mc_mesh/istio-mesh

terraform init
terraform plan
terraform apply

cd - 
```

### Configure Istio Addons

```bash
cd terraform/examples/mc_mesh/istio-addons

terraform init
terraform plan
terraform apply

cd - 
```

### Deploy sample apps

```bash
cd terraform/examples/mc_mesh/apps

terraform init
terraform plan
terraform apply

cd - 
```
