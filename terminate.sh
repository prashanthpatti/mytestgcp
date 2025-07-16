#!/bin/bash

set -euo pipefail

# === Configuration ===
CONFIG_FILE="./tf-project/config.env"
TF_DIR="./tf-project"
TFVARS_FILE="$TF_DIR/vars.tfvars"

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

    for var in PROJECT_ID PROJECT_NAME ENV REGION; do
        if [ -z "${!var:-}" ]; then
            echo "❌ Missing required variable: $var in $CONFIG_FILE"
            exit 1
        fi
    done
}

# === Regenerate vars.tfvars for consistency ===
write_tfvars() {
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

# === Execution ===

load_config
write_tfvars

echo "🧨 Preparing to destroy Terraform resources for project: $PROJECT_ID"

cd "$TF_DIR" || { echo "❌ Failed to change directory to $TF_DIR"; exit 1; }

echo "🔥 Running terraform destroy..."
terraform init -reconfigure -input=false
terraform destroy -var-file="vars.tfvars" -auto-approve

# === Optional GCP project deletion ===
echo
while true; do
    read -rp "❓ Do you want to delete the entire GCP project '$PROJECT_ID'? [y/N]: " DELETE_PROJECT
    DELETE_PROJECT=${DELETE_PROJECT:-N}
    case "$DELETE_PROJECT" in
        [Yy]*)
            echo "🗑 Deleting GCP project: $PROJECT_ID"
            if gcloud projects describe "$PROJECT_ID" >/dev/null 2>&1; then
                gcloud projects delete "$PROJECT_ID" --quiet
                echo "✅ GCP project deleted successfully"
            else
                echo "⚠️ Project '$PROJECT_ID' does not exist or is already deleted"
            fi
            break
            ;;
        [Nn]*)
            echo "✅ Terraform resources destroyed. GCP project preserved."
            break
            ;;
        *)
            echo "⚠️ Please enter 'y' or 'n'"
            ;;
    esac
done

echo "✅ Destroy process complete!"
