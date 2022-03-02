# Copyright 2022 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


#...............................................................................
terraform {
  required_version = ">= 1.1.4"
}


# EKS Cluster
#...............................................................................
module "cluster_eks" {
  source = "../../../modules/cluster-eks"
}


# GKE - Network
#...............................................................................
module "network_gke" {
  source = "../../../modules/network-gke-cft"

  project       = var.gcp_project
  network_name  = var.gcp_network
  subnet_region = var.gcp_region
}


# GKE Cluster
#...............................................................................
module "cluster_gke" {
  source = "../../../modules/cluster-gke-cft"

  project            = var.gcp_project
  cluster_name       = var.gcp_cluster_name
  cluster_region     = var.gcp_region
  cluster_admin_user = var.gcp_cluster_admin_user

  network_name            = module.network_gke.network_name
  subnet_name             = module.network_gke.subnet_name
  subnet_secondary_ranges = module.network_gke.subnet_secondary_ranges
}


#...............................................................................
locals {
  istio_manifests_location = "../../../../manifests/istio/"
  istio_version_path       = "../../../../environment/istio-${var.istio_version}/"

  eks_context                   = module.cluster_eks.cluster_arn
  eks_fetch_credentials_command = <<-EOT
    aws eks --region ${module.cluster_eks.region} update-kubeconfig \
    --name ${module.cluster_eks.cluster_name}
  EOT

  gke_context = "gke_${var.gcp_project}_${var.gcp_region}_${module.cluster_gke.cluster_name}"

  gke_fetch_credentials_command = <<-EOT
    gcloud container clusters get-credentials ${module.cluster_gke.cluster_name} \
    --region ${var.gcp_region} --project ${var.gcp_project}
  EOT
}


# Credentials
#...............................................................................
module "cluster_eks_credentials" {
  source = "../../../modules/credentials"

  context                   = local.eks_context
  istio_version_path        = local.istio_version_path
  fetch_credentials_command = local.eks_fetch_credentials_command

  dependencies  = [module.cluster_eks]
  wait_for_secs = "60s"
}


module "cluster_gke_credentials" {
  source = "../../../modules/credentials"

  context                   = local.gke_context
  istio_version_path        = local.istio_version_path
  fetch_credentials_command = local.gke_fetch_credentials_command

  dependencies = [module.cluster_gke]
}


# Outputs
#...............................................................................
output "data" {
  value = {
    "cluster_eks" : {
      "context" : local.eks_context
      "fetch_credentials_command" : local.eks_fetch_credentials_command,
    },
    "cluster_gke" : {
      "context" : local.gke_context,
      "fetch_credentials_command" : local.gke_fetch_credentials_command,
    },
    "other" : {
      "istio_version" : var.istio_version,
      "istio_version_path" : local.istio_version_path,
      "istio_manifests_location" : local.istio_manifests_location,
    }
  }

  sensitive = true
}
