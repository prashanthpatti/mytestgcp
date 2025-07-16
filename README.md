Here's a **professionally structured `README.md`** in chronological format tailored for your **Ubuntu-only GCP Project Bootstrap & Terraform Automation** repository. This version improves clarity, consistency, and professionalism while preserving all the technical details you shared:

---

````markdown
# 🚀 GCP Project Bootstrap & Terraform Automation (Ubuntu-Only)

This repository automates the provisioning and management of **Google Cloud Projects** and key infrastructure components — including **Cloud Functions**, **Load Balancers**, **Service Accounts**, and **IAM Policies** — using **Terraform** and **Bash scripting**.

> ⚠️ **Note:** This project is designed and tested exclusively on **Ubuntu-based environments**. Other operating systems (e.g., Windows/macOS) are not supported.

---

## 📁 Repository Structure

```text
.
├── execute.sh               # Bootstraps project, enables APIs, and applies Terraform
├── terminate.sh             # Destroys all Terraform-managed resources
├── tf-project/
│   ├── backend.tf           # Remote backend config (GCS bucket)
│   ├── config.env           # User-defined config (project name, billing info, region)
│   ├── main.tf              # Terraform code using reusable modules
│   ├── outputs.tf           # Terraform output definitions
│   ├── variables.tf         # Input variable declarations
│   ├── vars.tfvars          # Auto-populated tfvars file
│   └── versions.tf          # Terraform and provider version requirements
├── function/
│   ├── main.py              # Python-based Cloud Function
│   └── function-source.zip  # Zipped artifact for deployment
````

---

## ⚙️ Prerequisites

Ensure the following before proceeding:

* **Operating System:** Ubuntu 20.04 or higher
* **Installed CLI Tools:**

  * [Terraform CLI](https://developer.hashicorp.com/terraform/downloads)
  * [gcloud CLI](https://cloud.google.com/sdk/docs/install)
* **GCP Billing Account**
* **GCP IAM User or Service Account** with the following permissions:

  * `resourcemanager.projects.create`
  * `billing.resourceAssociations.create`
  * `serviceusage.services.enable`
  * `roles/iam.admin`
  * `roles/compute.networkAdmin`

---

## 🔧 Required GCP APIs

These APIs must be enabled (automatically via script or manually):

* Cloud Resource Manager API
* IAM API
* Cloud Functions API
* Cloud Run API
* VPC Access API
* Cloud Build API
* Artifact Registry API

---

## ☁️ Backend Configuration (One-Time Setup)

1. Create a GCS bucket for remote Terraform state:

```bash
gsutil mb -l us-central1 gs://<your-unique-bucket-name>
```

2. Edit the backend configuration in `tf-project/backend.tf`:

```hcl
backend "gcs" {
  bucket = "<your-unique-bucket-name>"
  prefix = "gcp-cloud-function/state"
}
```

> ⚠️ This is a one-time manual setup. Terraform cannot create its own backend bucket.

---

## 🧾 Naming Conventions

Use the following naming pattern to ensure consistency and compliance:

```
<env>-<project_name>-<resource_type>
```

| Component       | Example        | Description                      |
| --------------- | -------------- | -------------------------------- |
| `env`           | `dev`          | Deployment environment           |
| `project_name`  | `pkumar-gcp`   | Lowercase, hyphenated identifier |
| `resource_type` | `sa`, `subnet` | Type-specific suffix             |

For special resources like **VPC Access Connector**:

* Must match regex: `^[a-z][-a-z0-9]{0,23}[a-z0-9]$`
* Maximum: 25 characters

Example:

```hcl
connector_name = "${var.env}-${substr(var.project_name, 0, 10)}-conn"
```

---

## 📥 Clone the Repository

```bash
git clone https://github.com/prashanthpatti/mygcprepo.git
cd mygcprepo
```

---

## 🔧 Configuration Steps

1. Edit the `tf-project/config.env` file:

```bash
project_name="myproject"
billing_account="YOUR-BILLING-ID"
region="us-central1"
```

> 💡 `project_id` will be generated automatically — **do not edit it manually**.

---

## 🚀 Deploy Infrastructure

Run the provisioning script:

```bash
./execute.sh
```

### What It Does:

* Creates or reuses a GCP project
* Links the billing account
* Enables required APIs
* Generates `vars.tfvars` with project ID
* Applies Terraform configuration

> ⏳ Note: VPC Access Connector creation may take a few minutes.

---

## 🌐 Access the Application

After successful deployment, output will include:

```hcl
load_balancer_ip = "34.xxx.xxx.xxx"
```

Access the deployed application:

```text
https://<load_balancer_ip>
```

> ⚠️ Only accessible if `is_public = true`.
> ℹ️ Cloud Function cold starts may cause slight delays.

---

## 🧹 Cleanup Resources

To tear down the infrastructure:

```bash
./terminate.sh
```

### This script will:

* Destroy all Terraform-managed resources
* Optionally delete the GCP project (with confirmation)

---

## ✅ Resources Managed

* Google Cloud Project
* Cloud Function (Gen2)
* VPC Network & Subnets
* VPC Access Connector
* HTTP(S) Load Balancer
* IAM Bindings
* GCS Bucket for source and state

---

## 🔐 Public vs Private Access

### Public Access (For demos/dev):

```hcl
is_public     = true
public_member = "allUsers"
```

### Private Access (Recommended for production):

```hcl
is_public     = true
public_member = "serviceAccount:internal-sa@project.iam.gserviceaccount.com"
```

For secure access:

* Use **IAP (Identity-Aware Proxy)**
* Use **signed identity tokens** from authenticated clients

> ❌ Cloud Run Gen2 + Serverless NEG does **not** support token forwarding via Load Balancer.

---

## 📌 Deployment Summary

| Use Case          | IAM Policy Example            | Supported |
| ----------------- | ----------------------------- | --------- |
| Public demo       | `run.invoker` + `allUsers`    | ✅ Yes     |
| Secure production | IAP or signed tokens          | ✅ Yes     |
| SA-only access    | Serverless NEG without tokens | ❌ No      |

---

## 🧠 Notes

* Ubuntu-only execution (tested on Ubuntu 20.04+)
* Scripts are re-runnable (idempotent design)
* Unique project names auto-generated via suffixing
* Logging and error handling are minimal (see TODOs)

---

## 🚧 Planned Enhancements

* Folder-level GCP project creation
* Selective module/resource destruction
* Enhanced CLI output and logging
* Advanced tfvars support for granular access control

---

## 📞 Support

Need help or customization?

* Open an [issue](https://github.com/prashanthpatti/mygcprepo/issues)
* Fork this repo and adapt it to your org's use case

```

---

Let me know if you'd like this in `.md` file format or want it tailored for multiple OS environments.
```
