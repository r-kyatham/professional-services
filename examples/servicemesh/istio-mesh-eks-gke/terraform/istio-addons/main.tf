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


data "terraform_remote_state" "clusters" {
  backend = "local"

  config = {
    path = "../clusters/terraform.tfstate"
  }
}


locals {
  rdata = data.terraform_remote_state.clusters.outputs.data

  cluster_eks_context = local.rdata["cluster_eks"].context
  cluster_gke_context = local.rdata["cluster_gke"].context

  istio_version            = local.rdata["other"].istio_version
  istio_version_path       = local.rdata["other"].istio_version_path
  istio_manifests_location = local.rdata["other"].istio_manifests_location
}


# EKS Cluster - Addons
#...............................................................................
module "cluster_eks_addons" {
  source = "../../../modules/istio-addons"

  context = local.cluster_eks_context

  istio_version_path       = local.istio_version_path
  istio_manifests_location = local.istio_manifests_location
}


# GKE Cluster - Addons
#...............................................................................
module "cluster_gke_addons" {
  source = "../../../modules/istio-addons"

  context = local.cluster_gke_context

  istio_version_path       = local.istio_version_path
  istio_manifests_location = local.istio_manifests_location
}
