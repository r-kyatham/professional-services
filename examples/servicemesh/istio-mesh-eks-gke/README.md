# Multi Cloud Istio Service Mesh



## 1. Introduction
This guide helps with
* Deploy EKS and GKE clusters
* Configure mesh between clusters
* Deploy sample application(s)
* Test the mesh and application(s)

> NOTE: For provisioning EKS cluster this guide uses the code from https://github.com/hashicorp/learn-terraform-provision-eks-cluster

> Note: For demonstration purposes this guide uses certs, sample apps distributed with the Istio version.


## 2. Prerequisites
Make sure the following prerequisites are completed
* Configure AWS permissions
  * Install ```aws``` cli
  * Create an AWS IAM users for Terraform.
  * In your AWS console, go to the IAM section and create a user
  * Add user to a group, attach following permissions to this group
    * AdministratorAccess
    * AmazonEKSClusterPolicy
  * Create access key ID and secret for the user and save those details
  * Configure aws
    ```bash
    aws configure
    ```

* Configure GCP permissions
  * Create a project
  * Associate billing with the project
  * Enable following APIs
    * compute.googleapis.com
    * container.googleapis.com
  * Provide following permissions to the user/Service Account(SA) that would deploy the solution
    * roles/compute.networkAdmin
    * roles/container.admin
    * roles/iam.serviceAccountCreator
    * roles/iam.serviceAccountDeleter
    * roles/iam.serviceAccountUser
    * roles/resourcemanager.projectIamAdmin
    * roles/serviceusage.serviceUsageAdmin
  * Configure gcloud
    ```bash
    gcloud init
    gcloud auth application-default login
    ```

* Clone code
   ```bash
   mkdir workspace && cd workspace

   git clone REPLACE_WITH_REPO_LINK

   cd REPLACE_WITH_REPO_NAME
   ```

* Download Istio
   ```bash
   export ISTIO_VERSION=1.12.2

   mkdir environment
   cd environment
   curl -sL https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -
   cd ../
   ```



## 3. Deployment Instructions
> See [here](docs/tf_steps.md) for deployment using terraform



## 4. Testing
#### Test EKS cluster

* Configure kubectl
  ```bash
  kubectl config get-contexts

  # Pick EKS context

  kubectl config use-context [REPLACE_WITH_EKS_CONTEXT_NAME]
  ```

* Test EKS URL's
  ```bash
  export eks_gateway=$(kubectl get service istio-ingressgateway \
    -n istio-system \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  ```

  ```bash
  export eks_product_page="http://${eks_gateway}/productpage"
  echo $eks_product_page
  curl -s -o /dev/null -w "%{http_code}" ${eks_product_page}
  ```

  ```bash
  export eks_hello_page="http://${eks_gateway}/hello"
  echo $eks_hello_page
  curl -s -o /dev/null -w "%{http_code}" ${eks_hello_page}
  ```

#### Test GKE cluster

* Configure kubectl
  ```bash
  kubectl config get-contexts

  # Pick GKE context

  kubectl config use-context [REPLACE_WITH_GKE_CONTEXT_NAME]
  ```

* Test GKE URL's
  ```bash
  export gke_gateway=$(kubectl -n istio-system get service istio-ingressgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  ```

  ```bash
  export gke_product_page="http://${gke_gateway}/productpage"
  echo $gke_product_page
  curl -s -o /dev/null -w "%{http_code}" ${gke_product_page}
  ```

  ```bash
  export gke_hello_page="http://${gke_gateway}/hello"
  echo $gke_hello_page
  curl -s -o /dev/null -w "%{http_code}" ${gke_hello_page}
  ```



## 5. Verify mesh on dashboard
* Configure kubectl
  ```bash
  kubectl config get-contexts

  # Pick GKE context

  kubectl config use-context [REPLACE_WITH_GKE_CONTEXT_NAME]
  ```

* Port forwarding
  ```bash
  kubectl port-forward --namespace istio-system $(kubectl get pod --namespace istio-system --selector="app.kubernetes.io/instance=kiali,app.kubernetes.io/name=kiali" --output jsonpath='{.items[0].metadata.name}') 8080:20001
  ```

* Navigate to [Kiali Dashboard](http://127.0.0.1:8080/kiali/console/graph/)



## 6. References
* https://learn.hashicorp.com/tutorials/terraform/eks
