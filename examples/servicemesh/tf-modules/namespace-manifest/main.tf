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


locals {
  kube_objs_split   = split("---", file("${var.manifest_file_path}"))
  kube_objs_chomped = [for e in local.kube_objs_split : chomp(e)]
  kube_objs_trimmed = [for e in local.kube_objs_chomped : trimspace(e)]
  kube_objs         = compact(local.kube_objs_trimmed)
}


# Apply Manifest
#...............................................................................
resource "kubernetes_manifest" "manifest" {
  for_each   = toset(local.kube_objs)
  manifest   = merge(yamldecode(each.key), { "metadata" : merge(yamldecode(each.key)["metadata"], { "namespace" : var.namespace }) })
  depends_on = [var.dependencies]
}
