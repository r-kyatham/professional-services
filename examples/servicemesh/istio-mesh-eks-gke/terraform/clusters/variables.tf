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


variable "istio_version" {
  description = "The version of istio to use"
  type        = string
  default     = "1.12.2"
}

variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_network" {
  description = "Name for the GCP network"
  type        = string
  default     = "demo"
}

variable "gcp_region" {
  description = "Name of the GCP region for network/cluster"
  type        = string
  default     = "us-central1"
}

variable "gcp_cluster_name" {
  description = "Name for GKE cluster"
  type        = string
  default     = "demo"
}

variable "gcp_cluster_admin_user" {
  description = "GKE cluster admin user for cluster role binding"
  type        = string
}
