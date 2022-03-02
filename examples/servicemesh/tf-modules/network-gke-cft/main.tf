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


# VPC Network
#...............................................................................
module "vpc" {
  source = "terraform-google-modules/network/google"
  # TODO: This throws version conflict.
  # version = "~> 3.0"

  project_id   = var.project
  network_name = "vpc-${var.network_name}"

  subnets = [
    {
      subnet_name   = "subnet-${var.subnet_region}"
      subnet_ip     = "10.128.0.0/20"
      subnet_region = "${var.subnet_region}"
      # TODO: Disable flow logs if not required.
      subnet_flow_logs          = "true"
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.2
      subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
    }
  ]

  secondary_ranges = {
    "subnet-${var.subnet_region}" = [
      {
        range_name    = "subnet-${var.subnet_region}-pods"
        ip_cidr_range = "10.60.0.0/14"
      },
      {
        range_name    = "subnet-${var.subnet_region}-services"
        ip_cidr_range = "10.64.0.0/20"
      },
    ]
  }
}
