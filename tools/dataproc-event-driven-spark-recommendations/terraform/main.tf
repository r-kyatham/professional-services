# Copyright 2022 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "cloud-function-source-bucket" {
    name     = "${var.project_id}-cloud-function-source"
    location = var.region
}

resource "google_storage_bucket" "dataproc-cluster-analysis-bucket" {
    name     = "${var.project_id}-dataproc-cluster-analysis"
    location = var.region
}

# Generates an archive of the source code compressed as a .zip file.
data "archive_file" "source" {
    type        = "zip"
    source_dir  = "../src"
    output_path = "/tmp/function.zip"
}

# Add source code zip to the Cloud Function's bucket
resource "google_storage_bucket_object" "cloud-function-zip" {
    source       = data.archive_file.source.output_path
    content_type = "application/zip"

    # Append to the MD5 checksum of the files's content
    # to force the zip to be updated as soon as a change occurs
    name         = "src-${data.archive_file.source.output_md5}.zip"
    bucket       = google_storage_bucket.cloud-function-source-bucket.name

    # Dependencies are automatically inferred so these lines can be deleted
    depends_on   = [
        google_storage_bucket.cloud-function-source-bucket,
        data.archive_file.source
    ]
}

# Create the Cloud function triggered by a `Finalize` event on the bucket
resource "google_cloudfunctions2_function" "dataproc-cluster-spark-property-monitoring" {
    name                  = "dataproc-cluster-spark-property-monitoring"
		location = var.region

		build_config {
		    runtime     = "python39"
		    entry_point = "execute" # Set the entry point in the code
				source {
		      storage_source {
		        bucket = google_storage_bucket.cloud-function-source-bucket.name
		        object = google_storage_bucket_object.cloud-function-zip.name
		      }
				 }
		}

service_config {
    max_instance_count  = 3
    min_instance_count = 1
    available_memory    = "256M"
    timeout_seconds     = 60
				environment_variables = {
		      PROJECT_ID = var.project_id
					REGION = var.region
					ZONE = var.zone
					BUCKET_NAME = google_storage_bucket.dataproc-cluster-analysis-bucket.name
		}
  }

event_trigger {
    trigger_region = "us-central1"
    event_type = "google.cloud.audit.log.v1.written"
    retry_policy = "RETRY_POLICY_RETRY"
    service_account_email = var.service_account_email
    event_filters {
      attribute = "serviceName"
      value = "dataproc.googleapis.com"
    }
    event_filters {
      attribute = "methodName"
      value = "google.cloud.dataproc.v1.ClusterController.CreateCluster"
    }
  }

    # Dependencies are automatically inferred so these lines can be deleted
    depends_on            = [
        google_storage_bucket.cloud-function-source-bucket,
        google_storage_bucket_object.cloud-function-zip
    ]
}
