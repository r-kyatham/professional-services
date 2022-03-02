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


# Deploy Bookinfo on EKS - Gateway only
#...............................................................................
module "cluster_eks_namespace_bookinfo" {
  source = "../../../modules/namespace"

  context = local.cluster_eks_context

  namespace = "bookinfo"
  labels = {
    istio-injection = "enabled"
  }
}


module "cluster_eks_gateway_bookinfo" {
  source = "../../../modules/namespace-manifest"

  context = local.cluster_eks_context

  namespace          = "bookinfo"
  manifest_file_path = "${local.bookinfo_app}/networking/bookinfo-gateway.yaml"

  dependencies = [module.cluster_eks_namespace_bookinfo]
}


#resource "kubernetes_manifest" "cluster_eks_gateway_bookinfo" {
#  for_each = toset(compact(split("---", file("${local.bookinfo_app}/networking/bookinfo-gateway.yaml"))))
#  manifest = merge(yamldecode(each.key), merge(yamldecode(each.key)["metadata"], { "namespace" : "bookinfo" }))
#
#  depends_on = [module.cluster_eks_namespace_bookinfo]
#}


# Deploy Bookinfo on GKE - Deployment and Gateway
#...............................................................................
module "cluster_gke_namespace_bookinfo" {
  source = "../../../modules/namespace"

  context = local.cluster_gke_context

  namespace = "bookinfo"
  labels = {
    istio-injection = "enabled"
  }
}


module "cluster_gke_deployment_bookinfo" {
  source = "../../../modules/namespace-manifest"

  context = local.cluster_gke_context

  namespace          = "bookinfo"
  manifest_file_path = "${local.bookinfo_app}/platform/kube/bookinfo.yaml"

  dependencies = [module.cluster_gke_namespace_bookinfo]
}


module "cluster_gke_gateway_bookinfo" {
  source = "../../../modules/namespace-manifest"

  context = local.cluster_gke_context

  namespace          = "bookinfo"
  manifest_file_path = "${local.bookinfo_app}/networking/bookinfo-gateway.yaml"

  dependencies = [module.cluster_gke_namespace_bookinfo]
}


#resource "kubernetes_manifest" "cluster_gke_deployment_bookinfo" {
#  for_each = toset(compact(split("---", file("${local.bookinfo_app}/platform/kube/bookinfo.yaml"))))
#  manifest = merge(yamldecode(each.key), merge(yamldecode(each.key)["metadata"], { "namespace" : "bookinfo" }))
#
#  depends_on = [module.cluster_gke_namespace_bookinfo]
#}


#resource "kubernetes_manifest" "cluster_gke_gateway_bookinfo" {
#  for_each = toset(compact(split("---", file("${local.bookinfo_app}/networking/bookinfo-gateway.yaml"))))
#  manifest = merge(yamldecode(each.key), merge(yamldecode(each.key)["metadata"], { "namespace" : "bookinfo" }))
#
#  depends_on = [module.cluster_gke_namespace_bookinfo]
#}
