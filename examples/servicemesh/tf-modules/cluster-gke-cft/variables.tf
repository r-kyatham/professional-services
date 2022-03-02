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


variable "project" {
  description = "The Project Id where things will be deployed"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster to be deployed"
  type        = string
}

variable "cluster_region" {
  description = "The region where cluster should be deployed"
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network where cluster will be deployed"
  type        = string
}

variable "subnet_name" {
  description = "The name of the VPC subnet where cluster will be deployed"
  type        = string
}

variable "subnet_secondary_ranges" {
  description = "The subnet secondary ranges"
  type        = list(any)
}

variable "cluster_admin_user" {
  description = "The user that will have cluster admin role"
  type        = string
}
