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
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = var.context
}


# Namespace
#...............................................................................
resource "kubernetes_namespace" "namespace" {
  # TODO: This seems to be throwing timeout during creation.
  # But kubernetes_namespace does not support create option for timeout block.

  metadata {
    annotations = {}

    name   = var.namespace
    labels = var.labels
  }

  depends_on = [var.dependencies]
}
