terraform {
  backend "gcs" {
    bucket  = "daughertyk8s-1-tf-state"
    prefix  = "iam"
  }
}

provider "google" {}

data "google_project" "project" {}

resource "google_service_account" "labs" {
  account_id   = "daugherty-labs"
  display_name = "Demo"
}

resource "google_service_account_key" "key" {
  service_account_id = "${google_service_account.labs.name}"
}

resource "google_project_iam_member" "service-account" {
  role   = "roles/editor"
  member = "serviceAccount:${google_service_account.labs.email}"
}

output "service_account_email" {
  value = "${google_service_account.labs.email}"
}
