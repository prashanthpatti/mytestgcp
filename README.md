# 🚀 GCP Project Bootstrap & Terraform Automation (Ubuntu-Only)

This repository provides an automated solution for provisioning and managing **Google Cloud Projects** and critical infrastructure components — including **Cloud Functions**, **Load Balancers**, **Service Accounts**, and **IAM Policies** — using **Terraform** and **Bash scripting**.

> ⚠️ **Note:** This project is designed and tested exclusively for **Ubuntu-based environments**. Execution in other operating systems (e.g., Windows, macOS) is not supported.

---

## 📁 Repository Structure

```text
.
├── execute.sh               # Script to bootstrap project, enable APIs, and apply Terraform
├── terminate.sh             # Script to destroy all Terraform-managed resources
├── tf-project/
│   ├── backend.tf           # GCS backend configuration for Terraform state
│   ├── config.env           # User configuration file (project name, billing info, region)
│   ├── main.tf              # Primary Terraform script using reusable modules
│   ├── outputs.tf           # Terraform outputs
│   ├── variables.tf         # Input variables definition
│   ├── vars.tfvars          # Auto-populated Terraform variables file
│   └── versions.tf          # Terraform and provider version constraints
├── function/
│   ├── main.py              # Cloud Function (Python) source code
│   └── function-source.zip  # Zipped artifact for Cloud Function deployment
⚙️ Prerequisites
Operating System: Ubuntu (20.04 or higher recommended)

Terraform CLI

gcloud CLI

GCP billing account

GCP IAM user or service account with the following permissions:

🔧 Required GCP APIs
Make sure the following APIs are enabled manually or automatically via script:

Cloud Resource Manager

IAM API

Cloud Functions API

Cloud Run API

VPC Access API

Cloud Build API

Artifact Registry

☁️ Backend Configuration (One-time Setup)
Create a GCS bucket to store your Terraform state:

bash
Copy
Edit
gsutil mb -l us-central1 gs://<your-unique-bucket-name>
Edit tf-project/backend.tf:

hcl
Copy
Edit
backend "gcs" {
  bucket = "<your-unique-bucket-name>"
  prefix = "gcp-cloud-function/state"
}
⚠️ This is a manual, one-time step. Terraform cannot provision its own backend bucket.

🔐 Required Permissions
Your service account or user must have the following IAM permissions:

resourcemanager.projects.create

billing.resourceAssociations.create

serviceusage.services.enable

IAM Administrator

VPC Network Admin

🧾 Naming Conventions
Follow this pattern to ensure compliance with GCP's naming constraints:

php-template
Copy
Edit
<env>-<project_name>-<resource_type>
Component	Example	Description
env	dev	Deployment environment
project_name	pkumar-gcp	Lowercase, hyphenated identifier
resource_type	sa, subnet, conn	Type-specific suffix

Special Constraints (e.g., VPC Access Connector)
Must match ^[a-z][-a-z0-9]{0,23}[a-z0-9]$

Max 25 characters total

Terraform-safe example:

hcl
Copy
Edit
connector_name = "${var.env}-${substr(var.project_name, 0, 10)}-conn"
📥 Clone the Repository
bash
Copy
Edit
git clone https://github.com/prashanthpatti/mygcprepo.git
cd mygcprepo
🔧 Configuration Steps
1️⃣ Fill in config.env
bash
Copy
Edit
project_name="myproject"
billing_account="YOUR-BILLING-ID"
region="us-central1"
💡 Do not manually set project_id; it is auto-generated during execution.

🚀 Deploy Infrastructure
Run the provisioning script:

bash
Copy
Edit
./execute.sh
What It Does:
Creates or reuses a GCP project

Links billing account

Enables required APIs

Generates and updates vars.tfvars with project_id

Applies Terraform modules to deploy resources

⏳ VPC Access Connector creation may take several minutes

🌐 Access the Application
After successful deployment, the output will include:

hcl
Copy
Edit
load_balancer_ip = "34.xxx.xxx.xxx"
Access the deployed application at:

url
Copy
Edit
https://<load_balancer_ip>
⚠️ Works only if is_public = true
ℹ️ Expect delays due to Cloud Function cold start and resource propagation

🧹 Cleanup Resources
To destroy infrastructure:

bash
Copy
Edit
./terminate.sh
This script:

Destroys all Terraform-managed resources

Optionally deletes the GCP project (confirmation prompt included)

✅ Resources Managed
GCP Project (with billing)

Cloud Function (Gen2)

VPC Network and Subnets

VPC Access Connector

HTTP(S) Load Balancer

IAM Bindings

Storage bucket for source code

🔐 Public vs. Private Access Options
Public Access
hcl
Copy
Edit
is_public     = true
public_member = "allUsers"
Used for unauthenticated HTTP access via Load Balancer.

Private/Secure Access (Recommended for Production)
hcl
Copy
Edit
is_public     = true
public_member = "serviceAccount:internal-sa@project.iam.gserviceaccount.com"
For private access:

Use IAP (Identity-Aware Proxy)

Use a signed identity token via authenticated client

❌ Cloud Run Gen2 + Serverless NEG does not support auth tokens from Load Balancer natively

📌 Deployment Summary
Use Case	IAM Policy Setting	Works?
Public demo	run.invoker + allUsers	✅ Yes
Secure prod	IAP or signed tokens	✅ Yes
SA-only access	NEG doesn't forward tokens	❌ No

🧠 Notes
Designed for Ubuntu OS only

Scripts are tested in Ubuntu 20.04+

execute.sh is re-runnable; it checks for existing projects

Project names are suffixed with random strings for uniqueness

🚧 Future Enhancements
Support for folder-level project placement

Selective resource/module destroy

Enhanced logging and error capture

More granular control over public access (via tfvars)

📞 Support
For custom setups, enhancements, or help using this project:

Open a GitHub issue

Fork the repo and adapt to your org's needs

markdown
Copy
Edit
