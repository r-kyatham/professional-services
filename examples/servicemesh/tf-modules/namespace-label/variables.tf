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


variable "dependencies" {
  description = "The dependencies that needs to be completed before"
  type        = list(any)
  default     = []
}

variable "namespace" {
  description = "The namespace that needs to be created"
  type        = string
}

variable "label" {
  description = "The namespace label"
  type        = string
}

variable "context" {
  description = "Cluster config name"
  type        = string
}

variable "istio_version_path" {
  description = "Path to istio version"
  type        = string
}
