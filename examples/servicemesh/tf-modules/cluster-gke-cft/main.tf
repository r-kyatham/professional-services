# Copyright 2021 Google Inc. All Rights Reserved.
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


# GKE cluster
#...............................................................................
# google_client_config and kubernetes provider must be explicitly specified like the following.

data "google_client_config" "default" {}


provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}


module "gke" {
  source     = "terraform-google-modules/kubernetes-engine/google"
  project_id = var.project
  name       = var.cluster_name
  region     = var.cluster_region

  network           = var.network_name
  subnetwork        = var.subnet_name
  ip_range_pods     = var.subnet_secondary_ranges[0].range_name
  ip_range_services = var.subnet_secondary_ranges[1].range_name

  network_policy = false

  node_pools_oauth_scopes = {
    default-node-pool = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }
}


resource "kubernetes_cluster_role_binding" "user_admin_binding" {
  metadata {
    name = "user_admin_binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "User"
    name      = var.cluster_admin_user
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [module.gke]
}
