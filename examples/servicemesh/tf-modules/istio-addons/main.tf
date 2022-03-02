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


# Addon - Kiali
# NOTE: Using this approach throws following error.
# Error: Call to function "yamldecode" failed.
#  unexpected extra content after value.
#...............................................................................
# resource "kubernetes_manifest" "istio_addon_kiali" {
#   manifest = yamldecode(file("${var.istio_version_path}/samples/addons/kiali.yaml"))
#   depends_on = [var.dependencies]
# }


# Addon - Prometheus
# NOTE: Using this approach throws following error.
# Error: Call to function "yamldecode" failed.
#  unexpected extra content after value.
#...............................................................................
# resource "kubernetes_manifest" "istio_addon_prometheus" {
#   manifest = yamldecode(file("${var.istio_version_path}/samples/addons/prometheus.yaml"))
#   depends_on = [var.dependencies]
# }


# Addon - Prometheus
# NOTE: Using this approach throws following error.
# Error: The terraform-provider-kubernetes_v2.6.0_x5 plugin crashed!
#   This is always indicative of a bug within the plugin. It would be immensely
#   helpful if you could report the crash with the plugin's maintainers so that it
#   can be fixed.
#...............................................................................
# resource "kubernetes_manifest" "istio_addon_prometheus" {
#   for_each = toset(compact(split("---", file("${var.istio_version_path}/samples/addons/prometheus.yaml")))) 
#   manifest = yamldecode(each.key)
#   depends_on = [var.dependencies]
# }


# Addon - Kiali
#...............................................................................
resource "null_resource" "istio_addon_kiali" {
  triggers = {
    istio_version_path = var.istio_version_path
    context            = var.context
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl --context ${var.context} apply -f ${var.istio_version_path}/samples/addons/kiali.yaml
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl --context ${self.triggers.context} delete -f ${self.triggers.istio_version_path}/samples/addons/kiali.yaml
    EOT
  }

  depends_on = [var.dependencies]
}


# Addon - Prometheus
#...............................................................................
resource "null_resource" "istio_addon_prometheus" {
  triggers = {
    istio_version_path = var.istio_version_path
    context            = var.context
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl --context ${var.context} apply -f ${var.istio_version_path}/samples/addons/prometheus.yaml
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl --context ${self.triggers.context} delete -f ${self.triggers.istio_version_path}/samples/addons/prometheus.yaml
    EOT
  }

  depends_on = [var.dependencies]
}


# Addon - Grafana
#...............................................................................
resource "null_resource" "istio_addon_grafana" {
  triggers = {
    istio_version_path = var.istio_version_path
    context            = var.context
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl --context ${var.context} apply -f ${var.istio_version_path}/samples/addons/grafana.yaml
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl --context ${self.triggers.context} delete -f ${self.triggers.istio_version_path}/samples/addons/grafana.yaml
    EOT
  }

  depends_on = [var.dependencies]
}


# Addon - Jaeger
#...............................................................................
resource "null_resource" "istio_addon_jaeger" {
  triggers = {
    istio_version_path = var.istio_version_path
    context            = var.context
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl --context ${var.context} apply -f ${var.istio_version_path}/samples/addons/jaeger.yaml
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl --context ${self.triggers.context} delete -f ${self.triggers.istio_version_path}/samples/addons/jaeger.yaml
    EOT
  }

  depends_on = [var.dependencies]
}


#...............................................................................
resource "null_resource" "complete" {
  depends_on = [
    resource.null_resource.istio_addon_kiali,
    resource.null_resource.istio_addon_prometheus,
    resource.null_resource.istio_addon_grafana,
    resource.null_resource.istio_addon_jaeger,
  ]
}
