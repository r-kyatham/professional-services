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


# Apply other manifests
# NOTE: This needs to be applied seperately from cluster creation
# since it looks for connecting to master during terraform plan 
#...............................................................................
resource "kubernetes_manifest" "istio_auth_policy" {
  manifest   = yamldecode(file("${var.istio_manifests_location}/auth_policy.yaml"))
  depends_on = [var.dependencies]
}


resource "kubernetes_manifest" "istio_expose_services" {
  manifest   = yamldecode(file("${var.istio_manifests_location}/expose_services.yaml"))
  depends_on = [var.dependencies]
}


# Remote Secrets
#...............................................................................
resource "null_resource" "remote_secrets" {
  triggers = {
    context            = var.context
    remote_context     = var.remote_context
    istio_cluster_type = var.istio_cluster_type
    istio_version_path = var.istio_version_path
  }

  provisioner "local-exec" {
    command = <<-EOT
      ${var.istio_version_path}/bin/istioctl x create-remote-secret \
      --context=${var.context} \
      --name=${var.istio_cluster_type} \
      | kubectl apply -f - --context=${var.remote_context}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      ${self.triggers.istio_version_path}/bin/istioctl x create-remote-secret \
      --context=${self.triggers.context} \
      --name=${self.triggers.istio_cluster_type} \
      | kubectl delete -f - --context=${self.triggers.remote_context}
    EOT
  }

  depends_on = [var.dependencies]
}


#...............................................................................
resource "null_resource" "complete" {
  depends_on = [
    resource.kubernetes_manifest.istio_auth_policy,
    resource.kubernetes_manifest.istio_expose_services,
    resource.null_resource.remote_secrets
  ]
}
