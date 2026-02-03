#!/bin/bash
#
# Setup GitHub secrets for CF deployment workflows
# Requires: gh CLI authenticated with repo access
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if gh CLI is installed and authenticated
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed."
        echo "Install it from: https://cli.github.com/"
        exit 1
    fi

    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI is not authenticated."
        echo "Run: gh auth login"
        exit 1
    fi

    print_success "GitHub CLI authenticated"
}

# Prompt for a secret value
prompt_secret() {
    local name="$1"
    local description="$2"
    local default="$3"
    local value

    echo -e "${YELLOW}$name${NC}: $description"
    if [ -n "$default" ]; then
        read -p "  Value [$default]: " value
        value="${value:-$default}"
    else
        read -p "  Value: " value
    fi
    echo "$value"
}

# Prompt for a password (hidden input)
prompt_password() {
    local name="$1"
    local description="$2"
    local value

    echo -e "${YELLOW}$name${NC}: $description"
    read -sp "  Value: " value
    echo
    echo "$value"
}

# Set a GitHub secret
set_secret() {
    local name="$1"
    local value="$2"

    if [ -z "$value" ]; then
        print_warning "Skipping $name (empty value)"
        return
    fi

    echo "$value" | gh secret set "$name"
    print_success "Set secret: $name"
}

# Setup secrets for standard deployment
setup_standard_deploy() {
    print_header "Standard Deployment Secrets (deploy.yml)"

    echo "This workflow deploys to Dev and Prod spaces within the SAME CF foundation."
    echo ""

    # Application config
    echo -e "\n${GREEN}--- Application Configuration ---${NC}\n"
    APP_UPSTREAM_REPO=$(prompt_secret "APP_UPSTREAM_REPO" "GitHub repo to watch (e.g., owner/repo-name)")
    APP_NAME=$(prompt_secret "APP_NAME" "Base application name (e.g., my-app)")

    # CF credentials (single foundation)
    echo -e "\n${GREEN}--- Cloud Foundry Configuration ---${NC}\n"
    CF_API=$(prompt_secret "CF_API" "CF API endpoint (e.g., https://api.sys.example.com)")
    CF_USERNAME=$(prompt_secret "CF_USERNAME" "CF username")
    CF_PASSWORD=$(prompt_password "CF_PASSWORD" "CF password")
    CF_ORG=$(prompt_secret "CF_ORG" "CF organization")
    CF_DEV_SPACE=$(prompt_secret "CF_DEV_SPACE" "CF dev space")
    CF_PROD_SPACE=$(prompt_secret "CF_PROD_SPACE" "CF production space")

    # Confirm and set
    echo ""
    print_header "Setting Secrets"

    set_secret "APP_UPSTREAM_REPO" "$APP_UPSTREAM_REPO"
    set_secret "APP_NAME" "$APP_NAME"
    set_secret "CF_API" "$CF_API"
    set_secret "CF_USERNAME" "$CF_USERNAME"
    set_secret "CF_PASSWORD" "$CF_PASSWORD"
    set_secret "CF_ORG" "$CF_ORG"
    set_secret "CF_DEV_SPACE" "$CF_DEV_SPACE"
    set_secret "CF_PROD_SPACE" "$CF_PROD_SPACE"

    print_success "Standard deployment secrets configured!"
}

# Setup secrets for blue-green deployment
setup_blue_green_deploy() {
    print_header "Blue-Green Deployment Secrets (blue-green-deploy.yml)"

    echo "This workflow supports DIFFERENT CF foundations for nonprod and prod."
    echo ""

    # Application config
    echo -e "\n${GREEN}--- Application Configuration ---${NC}\n"
    APP_UPSTREAM_REPO=$(prompt_secret "APP_UPSTREAM_REPO" "GitHub repo to watch (e.g., owner/repo-name)")
    APP_NAME=$(prompt_secret "APP_NAME" "Base application name (e.g., my-app)")
    APP_ROUTE_NONPROD=$(prompt_secret "APP_ROUTE_NONPROD" "Nonprod route domain (e.g., my-app.apps.nonprod.example.com)")
    APP_ROUTE_PROD=$(prompt_secret "APP_ROUTE_PROD" "Prod route domain (e.g., my-app.apps.prod.example.com)")

    # Nonprod CF foundation
    echo -e "\n${GREEN}--- Nonprod CF Foundation ---${NC}\n"
    CF_NONPROD_API=$(prompt_secret "CF_NONPROD_API" "Nonprod CF API (e.g., https://api.sys.nonprod.example.com)")
    CF_NONPROD_USERNAME=$(prompt_secret "CF_NONPROD_USERNAME" "Nonprod CF username")
    CF_NONPROD_PASSWORD=$(prompt_password "CF_NONPROD_PASSWORD" "Nonprod CF password")
    CF_NONPROD_ORG=$(prompt_secret "CF_NONPROD_ORG" "Nonprod CF organization")
    CF_NONPROD_SPACE=$(prompt_secret "CF_NONPROD_SPACE" "Nonprod CF space")

    # Prod CF foundation
    echo -e "\n${GREEN}--- Prod CF Foundation ---${NC}\n"
    CF_PROD_API=$(prompt_secret "CF_PROD_API" "Prod CF API (e.g., https://api.sys.prod.example.com)")
    CF_PROD_USERNAME=$(prompt_secret "CF_PROD_USERNAME" "Prod CF username")
    CF_PROD_PASSWORD=$(prompt_password "CF_PROD_PASSWORD" "Prod CF password")
    CF_PROD_ORG=$(prompt_secret "CF_PROD_ORG" "Prod CF organization")
    CF_PROD_SPACE=$(prompt_secret "CF_PROD_SPACE" "Prod CF space")

    # Confirm and set
    echo ""
    print_header "Setting Secrets"

    set_secret "APP_UPSTREAM_REPO" "$APP_UPSTREAM_REPO"
    set_secret "APP_NAME" "$APP_NAME"
    set_secret "APP_ROUTE_NONPROD" "$APP_ROUTE_NONPROD"
    set_secret "APP_ROUTE_PROD" "$APP_ROUTE_PROD"
    set_secret "CF_NONPROD_API" "$CF_NONPROD_API"
    set_secret "CF_NONPROD_USERNAME" "$CF_NONPROD_USERNAME"
    set_secret "CF_NONPROD_PASSWORD" "$CF_NONPROD_PASSWORD"
    set_secret "CF_NONPROD_ORG" "$CF_NONPROD_ORG"
    set_secret "CF_NONPROD_SPACE" "$CF_NONPROD_SPACE"
    set_secret "CF_PROD_API" "$CF_PROD_API"
    set_secret "CF_PROD_USERNAME" "$CF_PROD_USERNAME"
    set_secret "CF_PROD_PASSWORD" "$CF_PROD_PASSWORD"
    set_secret "CF_PROD_ORG" "$CF_PROD_ORG"
    set_secret "CF_PROD_SPACE" "$CF_PROD_SPACE"

    print_success "Blue-green deployment secrets configured!"
}

# Main menu
main() {
    print_header "CF Deployment Secrets Setup"

    check_gh_cli

    echo "Which workflow do you want to configure?"
    echo ""
    echo "  1) Standard Deployment (deploy.yml)"
    echo "     - Single CF foundation"
    echo "     - Dev and Prod spaces"
    echo ""
    echo "  2) Blue-Green Deployment (blue-green-deploy.yml)"
    echo "     - Separate nonprod/prod CF foundations"
    echo "     - Zero-downtime deployments"
    echo ""
    echo "  3) Both workflows"
    echo ""
    read -p "Enter choice [1-3]: " choice

    case $choice in
        1)
            setup_standard_deploy
            ;;
        2)
            setup_blue_green_deploy
            ;;
        3)
            setup_standard_deploy
            setup_blue_green_deploy
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac

    echo ""
    print_header "Setup Complete"
    echo "Don't forget to create the 'production' environment in:"
    echo "  Settings > Environments > New environment"
    echo ""
    echo "Enable 'Required reviewers' for manual approval before prod deployments."
}

main "$@"
