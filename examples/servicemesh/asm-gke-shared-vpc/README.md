# ASM - Private GKE clusters with Shared VPC



## 1. Introduction
This guide helps with
* Provision a shared VPC
* Deploy private zonal GKE clusters in different service projects
* Configure Mesh CA
* Install ASM in-cluster control plane
* Set up fleet project to view and manage service mesh
* Deploy sample application(s)
* Test the mesh and application(s)



## 2. Prerequisites
Make sure the following prerequisites are completed
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
* Folders and projects
  * Create a folder under GCP org to host all the projects that will be created below
    * For example: asm_example
  * Create following four projects under the above folder with a common suffix
    * For example: If suffix is ``asm001`` the project names/ids will look like
    ```
    1. host-project-asm001
    2. service-project-1-asm001
    3. service-project-2-asm001
    4. fleet-project-asm001
    ```
  * Associate billing with the above projects
* Permissions
  * Make sure the user/SA account has following permissions at the folder level
    * Compute Shared VPC Admin
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



## 3. Install
### Export vars
* Common vars - Replace values and export following variables
  * ORG_ID - GCP Org ID
  * FOLDER_ID - The folder where projects in the previous step were created
  * SUFFIX - The suffix used in previous step while creating projects


  ```bash
  # NOTE: These need to be updated before proceeding with the next steps.

  export ORG_ID=[REPLACE_WITH_ORG_ID]
  export FOLDER_ID=[REPLACE_WITH_FOLDER_ID]
  export SUFFIX=[REPLACE_WITH_SUFFIX]
  ```

* Export project details - Grab project_id, project_name, project_number details for the projects

  ```bash
  export HOST_PROJECT_ID=host-project-$SUFFIX
  export HOST_PROJECT_NAME=host-project-$SUFFIX
  export HOST_PROJECT_NUM=`gcloud projects describe host-project-$SUFFIX --format=json | jq -r .projectNumber`

  export SERVICE_PROJECT_1_ID=service-project-1-$SUFFIX
  export SERVICE_PROJECT_1_NAME=service-project-1-$SUFFIX
  export SERVICE_PROJECT_1_NUM=`gcloud projects describe service-project-1-$SUFFIX --format=json | jq -r .projectNumber`

  export SERVICE_PROJECT_2_ID=service-project-2-$SUFFIX
  export SERVICE_PROJECT_2_NAME=service-project-2-$SUFFIX
  export SERVICE_PROJECT_2_NUM=`gcloud projects describe service-project-2-$SUFFIX --format=json | jq -r .projectNumber`

  export FLEET_PROJECT_ID=fleet-project-$SUFFIX
  export FLEET_PROJECT_NAME=fleet-project-$SUFFIX
  export FLEET_PROJECT_NUM=`gcloud projects describe fleet-project-$SUFFIX --format=json | jq -r .projectNumber`
  ```

* Export common details for network and cluster

  ```bash
  # Update below details as required.

  export NETWORK=shared-net

  export SUBNET_1=tier-1
  export SUBNET_1_REGION=us-central1
  export SUBNET_1_PRIMARY_RANGE=10.1.0.0/16

  export CLUSTER_1=cluster-1
  export CLUSTER_1_PODS_PREFIX="$SUBNET_1"-pods
  export CLUSTER_1_SERVICES_PREFIX="$SUBNET_1"-services
  export CLUSTER_1_PODS_RANGE=10.4.0.0/20
  export CLUSTER_1_SERVICES_RANGE=10.8.0.0/16

  export SUBNET_2=tier-2
  export SUBNET_2_REGION=us-central1
  export SUBNET_2_PRIMARY_RANGE=10.16.0.0/16

  export CLUSTER_2=cluster-2
  export CLUSTER_2_PODS_PREFIX="$SUBNET_2"-pods
  export CLUSTER_2_SERVICES_PREFIX="$SUBNET_2"-services
  export CLUSTER_2_PODS_RANGE=10.19.0.0/20
  export CLUSTER_2_SERVICES_RANGE=10.23.0.0/16

  export USER_ACCOUNT=$(gcloud config list | grep account | cut -d' ' -f3 | head -n 1)
  ```



### Remove default project
```bash
gcloud config unset project
```



### Enable API's
* Host project
  ```bash
  gcloud services enable container.googleapis.com --project $HOST_PROJECT_ID
  ```

* Service project 1
  ```bash
  # fixme: Verify if all these API's are required in service project
  gcloud services enable container.googleapis.com \
      cloudbuild.googleapis.com  \
      cloudresourcemanager.googleapis.com \
      gkeconnect.googleapis.com \
      gkehub.googleapis.com \
      meshca.googleapis.com \
      meshconfig.googleapis.com \
      stackdriver.googleapis.com \
      --project $SERVICE_PROJECT_1_ID
  ```

* Service project 2
  ```bash
  # fixme: Verify if all these API's are required in service project
  gcloud services enable container.googleapis.com \
      cloudbuild.googleapis.com  \
      cloudresourcemanager.googleapis.com \
      gkeconnect.googleapis.com \
      gkehub.googleapis.com \
      meshca.googleapis.com \
      meshconfig.googleapis.com \
      stackdriver.googleapis.com \
      --project $SERVICE_PROJECT_2_ID
  ```

* Fleet project
  ```bash
  gcloud services enable anthos.googleapis.com \
      gkehub.googleapis.com \
      meshca.googleapis.com \
      meshconfig.googleapis.com \
      --project=$FLEET_PROJECT_ID
  ```



### Shared VPC
* Host project and networks
  ```bash
  gcloud compute networks create $NETWORK \
      --subnet-mode custom \
      --project $HOST_PROJECT_ID

  # fixme: Should secondary ranges be created here or while creating the cluster?

  gcloud compute networks subnets create $SUBNET_1 \
      --project $HOST_PROJECT_ID \
      --network $NETWORK \
      --region $SUBNET_1_REGION \
      --range $SUBNET_1_PRIMARY_RANGE \
      --secondary-range $CLUSTER_1_SERVICES_PREFIX=$CLUSTER_1_SERVICES_RANGE,$CLUSTER_1_PODS_PREFIX=$CLUSTER_1_PODS_RANGE \
      --enable-private-ip-google-access

  gcloud compute networks subnets create $SUBNET_2 \
      --project $HOST_PROJECT_ID \
      --network $NETWORK \
      --region $SUBNET_2_REGION \
      --range $SUBNET_2_PRIMARY_RANGE \
      --secondary-range $CLUSTER_2_SERVICES_PREFIX=$CLUSTER_2_SERVICES_RANGE,$CLUSTER_2_PODS_PREFIX=$CLUSTER_2_PODS_RANGE \
      --enable-private-ip-google-access
  ```

* Shared VPC and associated projects
  ```bash
  gcloud beta compute shared-vpc enable $HOST_PROJECT_ID

  gcloud beta compute shared-vpc associated-projects add $SERVICE_PROJECT_1_ID \
      --host-project $HOST_PROJECT_ID

  gcloud beta compute shared-vpc associated-projects add $SERVICE_PROJECT_2_ID \
      --host-project $HOST_PROJECT_ID
  ```

* IAM policy for Subnet 1
  ```bash
  # fixme: can we pass text to set iam policy?

  export ETAG=$(gcloud compute networks subnets get-iam-policy $SUBNET_1 \
     --project $HOST_PROJECT_ID \
     --region $SUBNET_1_REGION | grep etag | cut -d' ' -f2)


  # Create a file named <prefix>-policy.yaml with below content
  # Note: Value of prefix should match value of SUBNET_1
  # For Example: If SUBNET_1 is tier-1 then file name is tier-1-policy.yaml
  # File Content:

  cat >> "${SUBNET_1}-policy.yaml" <<EOF
  bindings:
  - members:
    - serviceAccount:SERVICE_PROJECT_1_NUM@cloudservices.gserviceaccount.com
    - serviceAccount:service-SERVICE_PROJECT_1_NUM@container-engine-robot.iam.gserviceaccount.com
    role: roles/compute.networkUser
  etag: ETAG
  EOF

  export SUBNET_1_POLICY="$SUBNET_1"-policy.yaml

  sed -i "s/ETAG/$ETAG/g" $SUBNET_1_POLICY
  sed -i "s/SERVICE_PROJECT_1_NUM/$SERVICE_PROJECT_1_NUM/g" $SUBNET_1_POLICY

  gcloud compute networks subnets set-iam-policy $SUBNET_1 \
      $SUBNET_1_POLICY \
      --project $HOST_PROJECT_ID \
      --region $SUBNET_1_REGION
  ```

* IAM policy for Subnet 2
  ```bash
  # fixme: can we pass text to set iam policy?
  export ETAG=$(gcloud compute networks subnets get-iam-policy $SUBNET_2 \
     --project $HOST_PROJECT_ID \
     --region $SUBNET_2_REGION | grep etag | cut -d' ' -f2)

  # Create a file named <prefix>-policy.yaml with below content
  # Note: Value of prefix should match value of SUBNET_2
  # For Example: If SUBNET_2 is tier-2 then file name is tier-2-policy.yaml
  # File Content:

  cat >> "${SUBNET_2}-policy.yaml" <<EOF
  bindings:
  - members:
    - serviceAccount:SERVICE_PROJECT_2_NUM@cloudservices.gserviceaccount.com
    - serviceAccount:service-SERVICE_PROJECT_2_NUM@container-engine-robot.iam.gserviceaccount.com
    role: roles/compute.networkUser
  etag: ETAG
  EOF

  export SUBNET_2_POLICY="$SUBNET_2"-policy.yaml

  sed -i "s/ETAG/$ETAG/g" $SUBNET_2_POLICY
  sed -i "s/SERVICE_PROJECT_2_NUM/$SERVICE_PROJECT_2_NUM/g" $SUBNET_2_POLICY

  gcloud compute networks subnets set-iam-policy $SUBNET_2 \
      $SUBNET_2_POLICY \
      --project $HOST_PROJECT_ID \
      --region $SUBNET_2_REGION
  ```



### Service Account IAM bindings
* Let service accounts manage Firewall resources in host project
  ```bash
  export ROLE_ID=gkeFirewallAdmin

  gcloud beta iam roles create $ROLE_ID \
      --title="GKE Firewall Admin" \
      --description="GKE SA Firewall Admin permissions" \
      --stage=GA \
      --permissions=compute.networks.updatePolicy,compute.firewalls.list,compute.firewalls.get,compute.firewalls.create,compute.firewalls.update,compute.firewalls.delete \
      --project=$HOST_PROJECT_ID

  gcloud projects add-iam-policy-binding $HOST_PROJECT_ID \
      --member=serviceAccount:service-$SERVICE_PROJECT_1_NUM@container-engine-robot.iam.gserviceaccount.com \
      --role=projects/$HOST_PROJECT_ID/roles/$ROLE_ID

  gcloud projects add-iam-policy-binding $HOST_PROJECT_ID \
      --member=serviceAccount:service-$SERVICE_PROJECT_2_NUM@container-engine-robot.iam.gserviceaccount.com \
      --role=projects/$HOST_PROJECT_ID/roles/$ROLE_ID
  ```

* Let service accounts perform network management operations in host project
  ```bash
  gcloud projects add-iam-policy-binding $HOST_PROJECT_ID \
      --member serviceAccount:service-$SERVICE_PROJECT_1_NUM@container-engine-robot.iam.gserviceaccount.com \
      --role roles/container.hostServiceAgentUser

  gcloud projects add-iam-policy-binding $HOST_PROJECT_ID \
      --member serviceAccount:service-$SERVICE_PROJECT_2_NUM@container-engine-robot.iam.gserviceaccount.com \
      --role roles/container.hostServiceAgentUser
  ```



### Verify usable subnet ranges
```bash
gcloud container subnets list-usable \
    --project $SERVICE_PROJECT_1_ID \
    --network-project $HOST_PROJECT_ID

gcloud container subnets list-usable \
    --project $SERVICE_PROJECT_2_ID \
    --network-project $HOST_PROJECT_ID
```



### Create private clusters
ASM requires you to have at least 8 vCPUs in node pools whose machine type is at least 4 vCPUs.

```bash
gcloud container clusters create $CLUSTER_1 \
    --enable-ip-alias \
    --enable-master-authorized-networks \
    --enable-private-nodes \
    --logging SYSTEM \
    --monitoring SYSTEM \
    --machine-type e2-standard-4 \
    --num-nodes=2 \
    --project $SERVICE_PROJECT_1_ID \
    --network projects/$HOST_PROJECT_ID/global/networks/$NETWORK \
    --subnetwork projects/$HOST_PROJECT_ID/regions/$SUBNET_1_REGION/subnetworks/$SUBNET_1 \
    --zone "$SUBNET_1_REGION"-a \
    --cluster-secondary-range-name $CLUSTER_1_PODS_PREFIX \
    --services-secondary-range-name $CLUSTER_1_SERVICES_PREFIX \
    --workload-pool="$SERVICE_PROJECT_1_ID.svc.id.goog" \
    --master-ipv4-cidr 172.16.0.0/28 \
    --labels=mesh_id="proj-$FLEET_PROJECT_NUM"
```

```bash
gcloud container clusters create $CLUSTER_2 \
    --enable-ip-alias \
    --enable-master-authorized-networks \
    --enable-private-nodes \
    --logging SYSTEM \
    --monitoring SYSTEM \
    --machine-type e2-standard-4 \
    --num-nodes=2 \
    --project $SERVICE_PROJECT_2_ID \
    --network projects/$HOST_PROJECT_ID/global/networks/$NETWORK \
    --subnetwork projects/$HOST_PROJECT_ID/regions/$SUBNET_2_REGION/subnetworks/$SUBNET_2 \
    --zone "$SUBNET_2_REGION"-a \
    --cluster-secondary-range-name $CLUSTER_2_PODS_PREFIX \
    --services-secondary-range-name $CLUSTER_2_SERVICES_PREFIX \
    --workload-pool="$SERVICE_PROJECT_2_ID.svc.id.goog" \
    --master-ipv4-cidr 172.17.0.0/28 \
    --labels=mesh_id="proj-$FLEET_PROJECT_NUM"
```


### Fetch Credentials
```bash
gcloud container clusters get-credentials $CLUSTER_1 \
    --project $SERVICE_PROJECT_1_ID \
    --zone "$SUBNET_1_REGION"-a

gcloud container clusters get-credentials $CLUSTER_2 \
    --project $SERVICE_PROJECT_2_ID \
    --zone "$SUBNET_2_REGION"-a
```



### Provide cloud shell access to GKE API
```bash
export SHELL_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
```

```bash
EXISTING_CIDR_1=`gcloud container clusters describe ${CLUSTER_1} --project ${SERVICE_PROJECT_1_ID} --zone ${SUBNET_1_REGION}-a \
 --format "value(masterAuthorizedNetworksConfig.cidrBlocks.cidrBlock)"`

gcloud container clusters update ${CLUSTER_1} \
    --project ${SERVICE_PROJECT_1_ID} \
    --zone ${SUBNET_1_REGION}-a \
    --enable-master-authorized-networks \
    --master-authorized-networks ${SHELL_IP}/32,${EXISTING_CIDR_1//;/,}
```


```bash
EXISTING_CIDR_2=`gcloud container clusters describe ${CLUSTER_2} --project ${SERVICE_PROJECT_2_ID} --zone ${SUBNET_2_REGION}-a \
 --format "value(masterAuthorizedNetworksConfig.cidrBlocks.cidrBlock)"`

gcloud container clusters update ${CLUSTER_2} \
    --project ${SERVICE_PROJECT_2_ID} \
    --zone ${SUBNET_2_REGION}-a \
    --enable-master-authorized-networks \
    --master-authorized-networks ${SHELL_IP}/32,${EXISTING_CIDR_2//;/,}
```



### Configure fleet project
```bash
gcloud beta services identity create --service=gkehub.googleapis.com --project=$FLEET_PROJECT_ID

# fixme: Are the below commands required? would role be added with --enable_all flag?
gcloud projects add-iam-policy-binding $FLEET_PROJECT_ID \
  --member "serviceAccount:service-$FLEET_PROJECT_NUM@gcp-sa-gkehub.iam.gserviceaccount.com" \
  --role roles/gkehub.serviceAgent

gcloud projects add-iam-policy-binding $SERVICE_PROJECT_1_ID \
  --member "serviceAccount:service-$FLEET_PROJECT_NUM@gcp-sa-gkehub.iam.gserviceaccount.com" \
  --role roles/gkehub.serviceAgent

gcloud projects add-iam-policy-binding $SERVICE_PROJECT_2_ID \
  --member "serviceAccount:service-$FLEET_PROJECT_NUM@gcp-sa-gkehub.iam.gserviceaccount.com" \
  --role roles/gkehub.serviceAgent
```



### asmcli
* Download asmcli
  ```bash
  curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_1.12 > asmcli
  chmod +x asmcli
  ```


* Cluster1 - rolebinding, namespace, validate, in-cluster control plane
  ```bash
  mkdir $CLUSTER_1

  cd $CLUSTER_1
  kubectl config use-context gke_${SERVICE_PROJECT_1_ID}_${SUBNET_1_REGION}-a_${CLUSTER_1}

  kubectl create clusterrolebinding cluster-admin-binding \
      --clusterrole=cluster-admin \
      --user=$USER_ACCOUNT

  kubectl create namespace istio-system

  ../asmcli validate \
    --project_id $SERVICE_PROJECT_1_ID \
    --fleet_id $FLEET_PROJECT_ID \
    --cluster_name $CLUSTER_1 \
    --cluster_location ${SUBNET_1_REGION}-a \
    --output_dir output

  export istioctl=./output/istioctl
  $istioctl experimental precheck

  # fixme: --managed option does not work
  # fixme: is it --enable_all or --enable-all? Logs say --enable-all and help says enable_all
  ../asmcli install \
    --project_id $SERVICE_PROJECT_1_ID \
    --cluster_name $CLUSTER_1 \
    --cluster_location ${SUBNET_1_REGION}-a \
    --fleet_id $FLEET_PROJECT_ID \
    --output_dir output \
    --enable_all \
    --ca mesh_ca \
    --verbose

  cd ../
  ```


* Cluster2 - rolebinding, namespace, validate, in-cluster control plane
  ```bash
  mkdir $CLUSTER_2

  cd $CLUSTER_2
  kubectl config use-context gke_${SERVICE_PROJECT_2_ID}_${SUBNET_2_REGION}-a_${CLUSTER_2}

  kubectl create clusterrolebinding cluster-admin-binding \
      --clusterrole=cluster-admin \
      --user=$USER_ACCOUNT

  kubectl create namespace istio-system

  ../asmcli validate \
    --project_id $SERVICE_PROJECT_2_ID \
    --fleet_id $FLEET_PROJECT_ID \
    --cluster_name $CLUSTER_2 \
    --cluster_location ${SUBNET_2_REGION}-a \
    --output_dir output

  export istioctl=./output/istioctl
  $istioctl experimental precheck

  # fixme: --managed option does not work
  # fixme: is it --enable_all or --enable-all? Logs say --enable-all and help says enable_all
  ../asmcli install \
    --project_id $SERVICE_PROJECT_2_ID \
    --cluster_name $CLUSTER_2 \
    --cluster_location ${SUBNET_2_REGION}-a \
    --fleet_id $FLEET_PROJECT_ID \
    --output_dir output \
    --enable_all \
    --ca mesh_ca \
    --verbose

  cd ../
  ```


### Firewall rules
* For cross-cluster communication
  ```bash
  function join_by
  {
    local IFS="$1"; shift; echo "$*";
  }
  ```

  ```bash
  ALL_CIDRS="$SUBNET_1_PRIMARY_RANGE,$SUBNET_2_PRIMARY_RANGE,$CLUSTER_1_PODS_RANGE,$CLUSTER_2_PODS_RANGE,$CLUSTER_1_SERVICES_RANGE,$CLUSTER_2_SERVICES_RANGE" 
  ALL_CLUSTER_NETTAGS=$(for P in $SERVICE_PROJECT_1_ID $SERVICE_PROJECT_2_ID; do gcloud --project $P compute instances list  --filter="name:($CLUSTER_1,$CLUSTER_2)" --format='value(tags.items.[0])' ; done | sort | uniq)
  ALL_NETTAGS=$(join_by , $(echo "${ALL_CLUSTER_NETTAGS}"))
  ```

  ```bash
  gcloud compute firewall-rules create istio-multicluster-pods \
      --project=$HOST_PROJECT_ID \
      --network=$NETWORK \
      --allow=tcp,udp,icmp,esp,ah,sctp \
      --direction=INGRESS \
      --priority=900 \
      --source-ranges="${ALL_CIDRS}" \
      --target-tags="${ALL_NETTAGS}" --quiet
  ```


* Fix firewall issue for port 15017
  ```bash
  export CLUSTER_1_FR_NAME=$(gcloud compute firewall-rules list \
      --filter="name~gke-${CLUSTER_1}-[0-9a-z]*-master" \
      --project $HOST_PROJECT_ID \
      --format json | jq -r '.[0].name')

  gcloud compute firewall-rules update $CLUSTER_1_FR_NAME --allow tcp:10250,tcp:443,tcp:15017 --project $HOST_PROJECT_ID

  export CLUSTER_2_FR_NAME=$(gcloud compute firewall-rules list \
      --filter="name~gke-${CLUSTER_2}-[0-9a-z]*-master" \
      --project $HOST_PROJECT_ID \
      --format json | jq -r '.[0].name')

  gcloud compute firewall-rules update $CLUSTER_2_FR_NAME --allow tcp:10250,tcp:443,tcp:15017 --project $HOST_PROJECT_ID
  ```



### Secrets
* Cluster-1 secret

  ```bash
  export CTX_1=gke_${SERVICE_PROJECT_1_ID}_${SUBNET_1_REGION}-a_${CLUSTER_1}

  cd $CLUSTER_1

  export istioctl=./output/istioctl

  # Create secrets for private clusters
  export PRIV_IP=`gcloud container clusters describe "${CLUSTER_1}" --project "${SERVICE_PROJECT_1_ID}" \
     --zone "${SUBNET_1_REGION}-a" --format "value(privateClusterConfig.privateEndpoint)"`

  $istioctl x create-remote-secret --context=${CTX_1} --name=${CLUSTER_1} --server=https://${PRIV_IP} > ${CTX_1}.secret

  cd ../
  ```


* Cluster-2 secret
  ```bash
  export CTX_2=gke_${SERVICE_PROJECT_2_ID}_${SUBNET_2_REGION}-a_${CLUSTER_2}

  cd $CLUSTER_2

  export istioctl=./output/istioctl

  # Create secrets for private clusters
  export PRIV_IP=`gcloud container clusters describe "${CLUSTER_2}" --project "${SERVICE_PROJECT_2_ID}" \
     --zone "${SUBNET_2_REGION}-a" --format "value(privateClusterConfig.privateEndpoint)"`

  $istioctl x create-remote-secret --context=${CTX_2} --name=${CLUSTER_2} --server=https://${PRIV_IP} > ${CTX_2}.secret

  cd ../
  ```

* Apply secrets
  ```bash
  export CTX_1=gke_${SERVICE_PROJECT_1_ID}_${SUBNET_1_REGION}-a_${CLUSTER_1}
  export CTX_2=gke_${SERVICE_PROJECT_2_ID}_${SUBNET_2_REGION}-a_${CLUSTER_2}

  kubectl apply -f ${CLUSTER_1}/${CTX_1}.secret --context=${CTX_2}
  kubectl apply -f ${CLUSTER_2}/${CTX_2}.secret --context=${CTX_1}
  ```



### Authorized networks
* Update Authorized networks
  ```bash
  POD_IP_CIDR_1=`gcloud container clusters describe ${CLUSTER_1} --project ${SERVICE_PROJECT_1_ID} --zone ${SUBNET_1_REGION}-a \
    --format "value(ipAllocationPolicy.clusterIpv4CidrBlock)"`

  EXISTING_CIDR_1=`gcloud container clusters describe ${CLUSTER_1} --project ${SERVICE_PROJECT_1_ID} --zone ${SUBNET_1_REGION}-a \
   --format "value(masterAuthorizedNetworksConfig.cidrBlocks.cidrBlock)"`

  POD_IP_CIDR_2=`gcloud container clusters describe ${CLUSTER_2} --project ${SERVICE_PROJECT_2_ID} --zone ${SUBNET_2_REGION}-a \
    --format "value(ipAllocationPolicy.clusterIpv4CidrBlock)"`

  EXISTING_CIDR_2=`gcloud container clusters describe ${CLUSTER_2} --project ${SERVICE_PROJECT_2_ID} --zone ${SUBNET_2_REGION}-a \
   --format "value(masterAuthorizedNetworksConfig.cidrBlocks.cidrBlock)"`

  gcloud container clusters update ${CLUSTER_1} \
      --project ${SERVICE_PROJECT_1_ID} \
      --zone ${SUBNET_1_REGION}-a \
      --enable-master-authorized-networks \
      --master-authorized-networks ${POD_IP_CIDR_2},${EXISTING_CIDR_1//;/,}

  gcloud container clusters update ${CLUSTER_2} \
      --project ${SERVICE_PROJECT_2_ID} \
      --zone ${SUBNET_2_REGION}-a \
      --enable-master-authorized-networks \
      --master-authorized-networks ${POD_IP_CIDR_1},${EXISTING_CIDR_2//;/,}
  ```

* Verify authorized networks
  ```bash
  gcloud container clusters describe ${CLUSTER_1} --project ${SERVICE_PROJECT_1_ID} --zone ${SUBNET_1_REGION}-a \
     --format "value(masterAuthorizedNetworksConfig.cidrBlocks.cidrBlock)"

  gcloud container clusters describe ${CLUSTER_2} --project ${SERVICE_PROJECT_2_ID} --zone ${SUBNET_2_REGION}-a \
     --format "value(masterAuthorizedNetworksConfig.cidrBlocks.cidrBlock)"
  ```



### Deploy application(s)
* Namespace(s) etc
  ```bash
  export CTX_1=gke_${SERVICE_PROJECT_1_ID}_${SUBNET_1_REGION}-a_${CLUSTER_1}
  export CTX_2=gke_${SERVICE_PROJECT_2_ID}_${SUBNET_2_REGION}-a_${CLUSTER_2}


  for CTX in ${CTX_1} ${CTX_2}
  do
    kubectl create namespace sample --context $CTX 
    export REVISION=$(kubectl get deploy -n istio-system --context $CTX \
        -l app=istiod -o \
        jsonpath={.items[*].metadata.labels.'istio\.io\/rev'}'{"\n"}')
    kubectl label namespace sample \
      --context $CTX \
      istio-injection- istio.io/rev=$REVISION --overwrite
  done
  ```


* Service(s)
  ```bash
  kubectl create --context=${CTX_1} \
      -f ./helloworld.yaml \
      -l service=helloworld -n sample

  kubectl create --context=${CTX_2} \
      -f ./helloworld.yaml \
      -l service=helloworld -n sample
  ```


* Deployment(s)
  ```bash
  kubectl create --context=${CTX_1} \
    -f ./helloworld.yaml \
    -l version=v1 -n sample

  kubectl create --context=${CTX_2} \
    -f ./helloworld.yaml \
    -l version=v2 -n sample
  ```

* Verify pods
  ```bash
  kubectl get pod --context=${CTX_1} -n sample
  kubectl get pod --context=${CTX_2} -n sample

  cd ../
  ```

* Ingress
  ```bash
  export NAMESPACE='gateway'

  kubectl config use-context gke_${SERVICE_PROJECT_1_ID}_${SUBNET_1_REGION}-a_${CLUSTER_1}

  kubectl create namespace $NAMESPACE

  export REVISION=$(kubectl get deploy -n istio-system -l app=istiod -o \
    jsonpath={.items[*].metadata.labels.'istio\.io\/rev'}'{"\n"}')

  kubectl label namespace $NAMESPACE \
    istio.io/rev=$REVISION --overwrite

  kubectl apply -n $NAMESPACE \
    -f ${CLUSTER_1}/output/samples/gateways/istio-ingressgateway

  kubectl config use-context gke_${SERVICE_PROJECT_2_ID}_${SUBNET_2_REGION}-a_${CLUSTER_2}

  kubectl create namespace $NAMESPACE

  export REVISION=$(kubectl get deploy -n istio-system -l app=istiod -o \
    jsonpath={.items[*].metadata.labels.'istio\.io\/rev'}'{"\n"}')

  kubectl label namespace $NAMESPACE \
    istio.io/rev=$REVISION --overwrite

  kubectl apply -n $NAMESPACE \
    -f ${CLUSTER_1}/output/samples/gateways/istio-ingressgateway
  ```



## 4. Configure Mesh metrics
* Go to Cloud Operations monitoring page in fleet project
* Add service projects to Metric scope of the fleet project



## 5. Verify
* Go to ASM console in fleet project
* Check mesh services and other details
