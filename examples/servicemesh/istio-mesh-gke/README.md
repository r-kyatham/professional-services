# Istio Service Mesh



## 1. Introduction
This guide helps with
* Provision networks
* Deploy GKE clusters
* Configure Istio service mesh between clusters
* Deploy sample application(s)
* Test the mesh and application(s)

> Note: For demonstration purposes this guide uses certs, sample apps distributed with the Istio version.



## 2. Prerequisites
Make sure the following prerequisites are completed
#### 2.1 Configure GCP permissions
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
#### 2.2 Clone code and download istio
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
> See [here](docs/tf_steps.md) for deploying with terraform



## 4. Testing
#### 4.1 Configure kubectl
  ```bash
  kubectl config get-contexts

  # Pick GKE context

  kubectl config use-context [REPLACE_WITH_GKE_CONTEXT_NAME]
  ```

#### 4.2 Test GKE URL's
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
#### 5.1 Configure kubectl
  ```bash
  kubectl config get-contexts

  # Pick GKE context

  kubectl config use-context [REPLACE_WITH_GKE_CONTEXT_NAME]
  ```

#### 5.2 Port forwarding
  ```bash
  kubectl port-forward --namespace istio-system $(kubectl get pod --namespace istio-system --selector="app.kubernetes.io/instance=kiali,app.kubernetes.io/name=kiali" --output jsonpath='{.items[0].metadata.name}') 8080:20001
  ```

#### 5.3 Navigate to [Kiali Dashboard](http://127.0.0.1:8080/kiali/console/graph/)
