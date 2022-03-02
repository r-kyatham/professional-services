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

    name   = "istio-system"
    labels = var.labels
  }

  depends_on = [var.dependencies]
}


# Certs
#...............................................................................
resource "kubernetes_secret" "ca_secret" {

  metadata {
    namespace = "istio-system"
    name      = "cacerts"
  }

  data = {
    "ca-cert.pem"    = file("${var.istio_version_path}/samples/certs/ca-cert.pem")
    "ca-key.pem"     = file("${var.istio_version_path}/samples/certs/ca-key.pem")
    "root-cert.pem"  = file("${var.istio_version_path}/samples/certs/root-cert.pem")
    "cert-chain.pem" = file("${var.istio_version_path}/samples/certs/cert-chain.pem")

  }

  depends_on = [resource.kubernetes_namespace.namespace]
}


# Istio install
# NOTE: null_resource does not support timeout.
# fixme: We can get into tricky situations is istio install fails. 
#...............................................................................
resource "null_resource" "istio_install" {
  triggers = {
    context  = var.context
    istioctl = "${var.istio_version_path}/bin/istioctl"

    istio_cluster_type       = var.istio_cluster_type
    istio_version_path       = var.istio_version_path
    istio_manifests_location = var.istio_manifests_location
  }

  provisioner "local-exec" {
    command = <<-EOT
      yes | ${var.istio_version_path}/bin/istioctl install \
        --context=${var.context} \
        -f ${var.istio_manifests_location}/cluster_${var.istio_cluster_type}.yaml
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      yes | ${self.triggers.istio_version_path}/bin/istioctl x uninstall \
        --context=${self.triggers.context} \
        -f ${self.triggers.istio_manifests_location}/cluster_${self.triggers.istio_cluster_type}.yaml
    EOT
  }

  depends_on = [resource.kubernetes_namespace.namespace,
  resource.kubernetes_secret.ca_secret]
}
