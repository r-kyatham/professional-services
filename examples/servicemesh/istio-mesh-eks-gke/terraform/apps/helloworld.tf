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


# Deploy Helloworld on EKS - Deployment and Gateway
#...............................................................................
module "cluster_eks_namespace_helloworld" {
  source = "../../../modules/namespace"

  context = local.cluster_eks_context

  namespace = "helloworld"
  labels = {
    istio-injection = "enabled"
  }
}


module "cluster_eks_deployment_helloworld" {
  source = "../../../modules/namespace-manifest"

  context = local.cluster_eks_context

  namespace          = "helloworld"
  manifest_file_path = "${local.helloworld_app}/helloworld.yaml"

  dependencies = [module.cluster_eks_namespace_helloworld]
}


module "cluster_eks_gateway_helloworld" {
  source = "../../../modules/namespace-manifest"

  context = local.cluster_eks_context

  namespace          = "helloworld"
  manifest_file_path = "${local.helloworld_app}/helloworld-gateway.yaml"

  dependencies = [module.cluster_eks_namespace_helloworld]
}


#resource "kubernetes_manifest" "cluster_eks_deployment_helloworld" {
#  for_each = toset(compact(split("---", file("${local.helloworld_app}/helloworld.yaml"))))
#  manifest = merge(yamldecode(each.key), merge(yamldecode(each.key)["metadata"], { "namespace" : "helloworld" }))
#
#  depends_on = [module.cluster_eks_namespace_helloworld]
#}


#resource "kubernetes_manifest" "cluster_eks_gateway_helloworld" {
#  for_each = toset(compact(split("---", file("${local.helloworld_app}/helloworld-gateway.yaml"))))
#  manifest = merge(yamldecode(each.key), merge(yamldecode(each.key)["metadata"], { "namespace" : "helloworld" }))
#
#  depends_on = [module.cluster_eks_namespace_helloworld]
#}


# Deploy Helloworld on GKE - Gateway only
#...............................................................................
module "cluster_gke_namespace_helloworld" {
  source = "../../../modules/namespace"

  context = local.cluster_gke_context

  namespace = "helloworld"
  labels = {
    istio-injection = "enabled"
  }
}


module "cluster_gke_gateway_helloworld" {
  source = "../../../modules/namespace-manifest"

  context = local.cluster_gke_context

  namespace          = "helloworld"
  manifest_file_path = "${local.helloworld_app}/helloworld-gateway.yaml"

  dependencies = [module.cluster_gke_namespace_helloworld]
}


#resource "kubernetes_manifest" "cluster_gke_gateway_helloworld" {
#  for_each = toset(compact(split("---", file("${local.helloworld_app}/helloworld-gateway.yaml"))))
#  manifest = merge(yamldecode(each.key), merge(yamldecode(each.key)["metadata"], { "namespace" : "helloworld" }))
#
#  depends_on = [module.cluster_gke_namespace_helloworld]
#}
