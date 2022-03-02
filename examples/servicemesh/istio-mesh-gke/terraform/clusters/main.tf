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


# GKE - Network
#...............................................................................
module "network_west" {
  source = "../../../modules/network-gke-cft"

  project       = var.gcp_project
  network_name  = "west"
  subnet_region = "west"
}


# GKE - Network
#...............................................................................
module "network_central" {
  source = "../../../modules/network-gke-cft"

  project       = var.gcp_project
  network_name  = "central"
  subnet_region = "central"
}


# GKE Cluster
#...............................................................................
module "cluster_west" {
  source = "../../../modules/cluster-gke-cft"

  project            = var.gcp_project
  cluster_name       = "west"
  cluster_region     = "us-west1"
  cluster_admin_user = var.gcp_cluster_admin_user

  network_name            = module.network_west.network_name
  subnet_name             = module.network_west.subnet_name
  subnet_secondary_ranges = module.network_west.subnet_secondary_ranges
}


# GKE Cluster
#...............................................................................
module "cluster_central" {
  source = "../../../modules/cluster-gke-cft"

  project            = var.gcp_project
  cluster_name       = "central"
  cluster_region     = "us-central1"
  cluster_admin_user = var.gcp_cluster_admin_user

  network_name            = module.network_central.network_name
  subnet_name             = module.network_central.subnet_name
  subnet_secondary_ranges = module.network_central.subnet_secondary_ranges
}


#...............................................................................
locals {
  istio_manifests_location = "../../../../manifests/istio/"
  istio_version_path       = "../../../../environment/istio-${var.istio_version}/"


  context_west = "gke_${var.gcp_project}_us-west1_${module.cluster_west.cluster_name}"

  fetch_credentials_command_west = <<-EOT
    gcloud container clusters get-credentials ${module.cluster_west.cluster_name} \
    --region us-west1 --project ${var.gcp_project}
  EOT

  context_central = "gke_${var.gcp_project}_us-central1_${module.cluster_central.cluster_name}"

  fetch_credentials_command_central = <<-EOT
    gcloud container clusters get-credentials ${module.cluster_central.cluster_name} \
    --region us-central1 --project ${var.gcp_project}
  EOT
}


# Credentials
#...............................................................................
module "cluster_credentials_west" {
  source = "../../../modules/credentials"

  context                   = local.context_west
  istio_version_path        = local.istio_version_path
  fetch_credentials_command = local.fetch_credentials_command_west

  # fixme: rename this to run_after
  dependencies  = [module.cluster_west]
  # fixme: rename this to initial_delay
  wait_for_secs = "60s"
}


module "cluster_credentials_central" {
  source = "../../../modules/credentials"

  context                   = local.context_central
  istio_version_path        = local.istio_version_path
  fetch_credentials_command = local.fetch_credentials_command_central

  dependencies = [module.cluster_central]
}


# Outputs
#...............................................................................
output "data" {
  value = {
    "cluster_west" : {
      "context" : local.context_west
      "fetch_credentials_command" : local.fetch_credentials_command_west,
    },
    "cluster_central" : {
      "context" : local.context_central,
      "fetch_credentials_command" : local.fetch_credentials_command_central,
    },
    "other" : {
      "istio_version" : var.istio_version,
      "istio_version_path" : local.istio_version_path,
      "istio_manifests_location" : local.istio_manifests_location,
    }
  }

  sensitive = true
}
