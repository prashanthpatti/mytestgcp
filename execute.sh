#!/bin/bash

set -euo pipefail

# === Configuration ===
CONFIG_FILE="./tf-project/config.env"
TFVARS_FILE="./tf-project/vars.tfvars"
PROJECT_SUFFIX=$(openssl rand -hex 3 2>/dev/null || tr -dc 'a-f0-9' </dev/urandom | head -c 6)

GCP_APIS=(
    cloudresourcemanager.googleapis.com
    cloudbilling.googleapis.com
    compute.googleapis.com
    iam.googleapis.com
    cloudfunctions.googleapis.com
    artifactregistry.googleapis.com
    vpcaccess.googleapis.com
    cloudbuild.googleapis.com
    run.googleapis.com
)

# === Load and Validate Config ===
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Config file not found: $CONFIG_FILE"
        exit 1
    fi

    set -a
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
    set +a

    for var in PROJECT_NAME ENV REGION IS_PUBLIC PUBLIC_MEMBER BILLING_ACCOUNT; do
        if [ -z "${!var:-}" ]; then
            echo "❌ Missing required variable: $var in $CONFIG_FILE"
            exit 1
        fi
    done
}

# === Enable API if Needed ===
check_and_enable_api() {
    local api=$1
    local project=$2
    if gcloud services list --project "$project" --format="value(NAME)" 2>/dev/null | grep -q "^$api$"; then
        echo "✅ API $api is already enabled"
    else
        echo "⚙️ Enabling $api API..."
        if ! gcloud services enable "$api" --project "$project" --quiet; then
            echo "❌ Failed to enable API: $api"
            exit 1
        fi
    fi
}

# === Write Terraform tfvars file ===
write_tfvars() {
    echo "📄 Generating Terraform vars file: $TFVARS_FILE"
    cat > "$TFVARS_FILE" <<EOF
project_name = "$PROJECT_NAME"
env = "$ENV"
region = "$REGION"
is_public = $IS_PUBLIC
public_member = "$PUBLIC_MEMBER"
billing_account = "$BILLING_ACCOUNT"
project_id = "$PROJECT_ID"
EOF
}

# === Main Execution ===
load_config

# Build full project name
FULL_PROJECT_NAME="${ENV}-${PROJECT_NAME}-${PROJECT_SUFFIX}"
echo "🔍 Checking if project exists: $FULL_PROJECT_NAME"
PROJECT_ID=$(gcloud projects list --filter="name:$FULL_PROJECT_NAME" --format="value(projectId)" --quiet)

if [ -z "$PROJECT_ID" ]; then
    echo "🆕 Creating new project: $FULL_PROJECT_NAME"
    PROJECT_ID="$FULL_PROJECT_NAME"

    if ! gcloud projects create "$PROJECT_ID" --name="$FULL_PROJECT_NAME" --quiet; then
        echo "❌ Failed to create project"
        exit 1
    fi

    echo "⏳ Waiting for project creation to complete..."
    while ! gcloud projects describe "$PROJECT_ID" >/dev/null 2>&1; do
        sleep 2
    done
    echo "🔗 Linking billing account..."
    if ! gcloud beta billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT" --quiet; then
        echo "❌ Failed to link billing account"
        exit 1
    fi

    echo "⚙️ Enabling required GCP APIs..."
    for api in "${GCP_APIS[@]}"; do
        check_and_enable_api "$api" "$PROJECT_ID"
    done
else
    echo "✅ Project already exists: $PROJECT_ID"
fi

# Optional: update PROJECT_ID in config.env
if grep -q "^PROJECT_ID=" "$CONFIG_FILE"; then
   sed -i "s|^PROJECT_ID=.*|PROJECT_ID=\"$PROJECT_ID\"|" "$CONFIG_FILE"
else
    echo "PROJECT_ID=\"$PROJECT_ID\"" >> "$CONFIG_FILE"
fi

# Generate tfvars
write_tfvars

# Configure gcloud
echo "🔧 Setting gcloud project: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"
gcloud auth application-default set-quota-project "$PROJECT_ID"

# Run Terraform
echo "🚀 Running Terraform..."
cd ./tf-project || { echo "❌ Failed to enter Terraform directory"; exit 1; }
terraform init -reconfigure -input=false
terraform apply -var-file="vars.tfvars" -auto-approve

echo "✅ Setup complete! Project ID: $PROJECT_ID"
