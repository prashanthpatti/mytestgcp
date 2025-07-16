module "vpc" {
  source           = "git::https://github.com/prashanthpatti/mygcp-tf-modules.git//vpc?ref=v1.0"
  vpc_name         = "${var.env}-${var.project_name}-vpc"
  subnet_name      = "${var.env}-${var.project_name}-subnet"
  subnet_cidr      = "10.10.0.0/24"
  connector_name   = "${var.env}-${substr(var.project_name, 0, 10)}-conn"
  connector_cidr   = "10.10.1.0/28"
  region           = var.region
  project_id       = var.project_id
  env              = var.env
  project_name     = var.project_name
}


module "cloud_function" {
  source         = "git::https://github.com/prashanthpatti/mygcp-tf-modules.git//cloud_function?ref=v1.0"
  name           = "${var.env}-${var.project_name}-fn-hello-world"
  region         = var.region
  source_bucket  = google_storage_bucket.function_source_bucket.name
  source_object  = google_storage_bucket_object.function_zip.name
  project_id     = var.project_id
  lb_invoker_sa_email   = module.service_account.email
  is_public = var.is_public
  vpc_connector  = module.vpc.vpc_connector
  public_member  = var.public_member
}

module "load_balancer" {
  source        = "git::https://github.com/prashanthpatti/mygcp-tf-modules.git//load_balancer?ref=v1.0"
  project_id    = var.project_id
  region        = var.region
  env           = var.env
  project_name  = var.project_name
  function_name = module.cloud_function.cloud_function_name
}

resource "null_resource" "zip_function" {
  provisioner "local-exec" {
    command = "cd ../function && zip -r function-source.zip main.py"
  }

  triggers = {
    always_run = timestamp()
  }
}

resource "google_storage_bucket" "function_source_bucket" {
  name          = "${var.env}-${var.project_name}-function-source"
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket_object" "function_zip" {
  name       = "function-source.zip"
  bucket     = google_storage_bucket.function_source_bucket.name
  source     = "../function/function-source.zip"
  depends_on = [null_resource.zip_function]
}

module "service_account" {
  source       = "git::https://github.com/prashanthpatti/mygcp-tf-modules.git//service_account?ref=v1.0"
  env          = var.env
  project_name = var.project_name
  project_id   = var.project_id
}

module "iam_lb_invoker" {
  source              = "git::https://github.com/prashanthpatti/mygcp-tf-modules.git//iam?ref=v1.0"
  project_id          = var.project_id
  lb_invoker_sa_email = module.service_account.email
}
