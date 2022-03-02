

### Provision Clusters
```bash
cd terraform/clusters

# update variables.tf as required

terraform init
terraform plan
terraform apply

cd - 
```

### Configure Istio

```bash
cd terraform/istio

terraform init
terraform plan
terraform apply

cd - 
```

### Configure Istio mesh

```bash
cd terraform/istio-mesh

terraform init
terraform plan
terraform apply

cd - 
```

### Configure Istio Addons

```bash
cd terraform/istio-addons

terraform init
terraform plan
terraform apply

cd - 
```

### Deploy sample apps

```bash
cd terraform/apps

terraform init
terraform plan
terraform apply

cd - 
```
