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
resource "time_sleep" "wait" {
  create_duration = var.wait_for_secs

  depends_on = [var.dependencies]
}


# Fetch credentials
# NOTE: This is required when --context has to be passed explicitly
#...............................................................................
resource "null_resource" "fetch_credentials" {
  triggers = {
    command            = var.fetch_credentials_command
    istio_version_path = var.istio_version_path
  }

  provisioner "local-exec" {
    command = <<-EOT
      ${var.fetch_credentials_command}
    EOT
  }

  depends_on = [var.dependencies, resource.time_sleep.wait]
}
