# Copyright 2022 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

project_id = "cloud-run-356420"
workflow_status_schema_name = "workflow_status_schema"
workflow_status_topics = ["workflow_status_topic"]
topics_subscriptions = {
    "workflow_status_topic": { 
        topic = "workflow_status_topic"
        subscription_for_dependencies = [
                       "workflow_1_pattern1,workflow_2_pattern1,on_success",
                ]
        }
}
composer_service_account="125433337717-compute@developer.gserviceaccount.com"
