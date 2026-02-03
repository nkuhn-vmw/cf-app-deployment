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
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC} ${BOLD}$1${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

print_subheader() {
    echo ""
    echo -e "${CYAN}── $1 ──${NC}"
    echo ""
}

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

print_bullet() {
    echo -e "  ${DIM}•${NC} $1"
}

# Check if gh CLI is installed and authenticated
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed."
        echo "    Install it from: https://cli.github.com/"
        exit 1
    fi

    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI is not authenticated."
        echo "    Run: gh auth login"
        exit 1
    fi

    REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "unknown")
    print_success "GitHub CLI authenticated"
    print_success "Target repository: ${BOLD}$REPO${NC}"
}

# Prompt for a secret value with better formatting
prompt_secret() {
    local name="$1"
    local example="$2"
    local value

    echo -e "  ${BOLD}$name${NC}"
    echo -e "  ${DIM}Example: $example${NC}"
    read -p "  > " value
    echo ""
    echo "$value"
}

# Prompt for a password (hidden input)
prompt_password() {
    local name="$1"
    local value

    echo -e "  ${BOLD}$name${NC}"
    echo -e "  ${DIM}(input hidden)${NC}"
    read -sp "  > " value
    echo ""
    echo ""
    echo "$value"
}

# Set a GitHub secret
set_secret() {
    local name="$1"
    local value="$2"

    if [ -z "$value" ]; then
        print_warning "Skipping $name (empty value)"
        return 1
    fi

    echo "$value" | gh secret set "$name" 2>/dev/null
    print_success "$name"
}

# Show what secrets are needed for standard deployment
show_standard_requirements() {
    print_header "Standard Deployment - Required Secrets"

    echo "This workflow deploys to Dev and Prod spaces within the SAME CF foundation."
    echo ""
    echo -e "${BOLD}Before you begin, gather the following information:${NC}"
    echo ""
    echo -e "${CYAN}Application Configuration:${NC}"
    print_bullet "APP_UPSTREAM_REPO  - GitHub repo to watch for releases"
    print_bullet "APP_NAME           - Your application's base name"
    echo ""
    echo -e "${CYAN}Cloud Foundry Credentials (single foundation):${NC}"
    print_bullet "CF_API             - API endpoint URL"
    print_bullet "CF_USERNAME        - Service account username"
    print_bullet "CF_PASSWORD        - Service account password"
    print_bullet "CF_ORG             - Organization name"
    print_bullet "CF_DEV_SPACE       - Development space name"
    print_bullet "CF_PROD_SPACE      - Production space name"
    echo ""
    echo -e "${DIM}Total: 8 secrets to configure${NC}"
    echo ""

    read -p "Press Enter when ready to continue (or Ctrl+C to cancel)..."
}

# Show what secrets are needed for blue-green deployment
show_blue_green_requirements() {
    print_header "Blue-Green Deployment - Required Secrets"

    echo "This workflow supports DIFFERENT CF foundations for nonprod and prod,"
    echo "with zero-downtime blue-green deployments."
    echo ""
    echo -e "${BOLD}Before you begin, gather the following information:${NC}"
    echo ""
    echo -e "${CYAN}Application Configuration:${NC}"
    print_bullet "APP_UPSTREAM_REPO  - GitHub repo to watch for releases"
    print_bullet "APP_NAME           - Your application's base name"
    print_bullet "APP_ROUTE_NONPROD  - Route domain for nonprod"
    print_bullet "APP_ROUTE_PROD     - Route domain for prod"
    echo ""
    echo -e "${CYAN}Nonprod CF Foundation:${NC}"
    print_bullet "CF_NONPROD_API      - Nonprod API endpoint"
    print_bullet "CF_NONPROD_USERNAME - Nonprod service account"
    print_bullet "CF_NONPROD_PASSWORD - Nonprod password"
    print_bullet "CF_NONPROD_ORG      - Nonprod organization"
    print_bullet "CF_NONPROD_SPACE    - Nonprod space"
    echo ""
    echo -e "${CYAN}Prod CF Foundation:${NC}"
    print_bullet "CF_PROD_API         - Prod API endpoint"
    print_bullet "CF_PROD_USERNAME    - Prod service account"
    print_bullet "CF_PROD_PASSWORD    - Prod password"
    print_bullet "CF_PROD_ORG         - Prod organization"
    print_bullet "CF_PROD_SPACE       - Prod space"
    echo ""
    echo -e "${DIM}Total: 14 secrets to configure${NC}"
    echo ""

    read -p "Press Enter when ready to continue (or Ctrl+C to cancel)..."
}

# Display collected values for confirmation
confirm_values() {
    local workflow="$1"
    shift
    local -n secrets_ref=$1

    print_header "Review Your Configuration"

    echo "Please verify these values before setting the secrets:"
    echo ""

    for key in "${!secrets_ref[@]}"; do
        value="${secrets_ref[$key]}"
        if [[ "$key" == *"PASSWORD"* ]]; then
            echo -e "  ${BOLD}$key${NC}: ${DIM}(hidden)${NC}"
        elif [ -z "$value" ]; then
            echo -e "  ${BOLD}$key${NC}: ${YELLOW}(empty - will be skipped)${NC}"
        else
            echo -e "  ${BOLD}$key${NC}: $value"
        fi
    done

    echo ""
    read -p "Set these secrets? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo ""
        print_warning "Cancelled. No secrets were set."
        exit 0
    fi
}

# Setup secrets for standard deployment
setup_standard_deploy() {
    show_standard_requirements

    print_header "Enter Secret Values"

    declare -A secrets

    print_subheader "Application Configuration"
    secrets[APP_UPSTREAM_REPO]=$(prompt_secret "APP_UPSTREAM_REPO" "owner/repo-name")
    secrets[APP_NAME]=$(prompt_secret "APP_NAME" "my-app")

    print_subheader "Cloud Foundry Credentials"
    secrets[CF_API]=$(prompt_secret "CF_API" "https://api.sys.example.com")
    secrets[CF_USERNAME]=$(prompt_secret "CF_USERNAME" "cf-deployer")
    secrets[CF_PASSWORD]=$(prompt_password "CF_PASSWORD")
    secrets[CF_ORG]=$(prompt_secret "CF_ORG" "my-org")
    secrets[CF_DEV_SPACE]=$(prompt_secret "CF_DEV_SPACE" "development")
    secrets[CF_PROD_SPACE]=$(prompt_secret "CF_PROD_SPACE" "production")

    confirm_values "standard" secrets

    print_header "Setting GitHub Secrets"

    local success_count=0
    for key in APP_UPSTREAM_REPO APP_NAME CF_API CF_USERNAME CF_PASSWORD CF_ORG CF_DEV_SPACE CF_PROD_SPACE; do
        if set_secret "$key" "${secrets[$key]}"; then
            ((success_count++))
        fi
    done

    echo ""
    print_success "Standard deployment configured! ($success_count secrets set)"
}

# Setup secrets for blue-green deployment
setup_blue_green_deploy() {
    show_blue_green_requirements

    print_header "Enter Secret Values"

    declare -A secrets

    print_subheader "Application Configuration"
    secrets[APP_UPSTREAM_REPO]=$(prompt_secret "APP_UPSTREAM_REPO" "owner/repo-name")
    secrets[APP_NAME]=$(prompt_secret "APP_NAME" "my-app")
    secrets[APP_ROUTE_NONPROD]=$(prompt_secret "APP_ROUTE_NONPROD" "my-app.apps.nonprod.example.com")
    secrets[APP_ROUTE_PROD]=$(prompt_secret "APP_ROUTE_PROD" "my-app.apps.prod.example.com")

    print_subheader "Nonprod CF Foundation"
    secrets[CF_NONPROD_API]=$(prompt_secret "CF_NONPROD_API" "https://api.sys.nonprod.example.com")
    secrets[CF_NONPROD_USERNAME]=$(prompt_secret "CF_NONPROD_USERNAME" "cf-deployer")
    secrets[CF_NONPROD_PASSWORD]=$(prompt_password "CF_NONPROD_PASSWORD")
    secrets[CF_NONPROD_ORG]=$(prompt_secret "CF_NONPROD_ORG" "my-org")
    secrets[CF_NONPROD_SPACE]=$(prompt_secret "CF_NONPROD_SPACE" "nonprod")

    print_subheader "Prod CF Foundation"
    secrets[CF_PROD_API]=$(prompt_secret "CF_PROD_API" "https://api.sys.prod.example.com")
    secrets[CF_PROD_USERNAME]=$(prompt_secret "CF_PROD_USERNAME" "cf-deployer")
    secrets[CF_PROD_PASSWORD]=$(prompt_password "CF_PROD_PASSWORD")
    secrets[CF_PROD_ORG]=$(prompt_secret "CF_PROD_ORG" "my-org")
    secrets[CF_PROD_SPACE]=$(prompt_secret "CF_PROD_SPACE" "prod")

    confirm_values "blue-green" secrets

    print_header "Setting GitHub Secrets"

    local success_count=0
    for key in APP_UPSTREAM_REPO APP_NAME APP_ROUTE_NONPROD APP_ROUTE_PROD \
               CF_NONPROD_API CF_NONPROD_USERNAME CF_NONPROD_PASSWORD CF_NONPROD_ORG CF_NONPROD_SPACE \
               CF_PROD_API CF_PROD_USERNAME CF_PROD_PASSWORD CF_PROD_ORG CF_PROD_SPACE; do
        if set_secret "$key" "${secrets[$key]}"; then
            ((success_count++))
        fi
    done

    echo ""
    print_success "Blue-green deployment configured! ($success_count secrets set)"
}

# Main menu
main() {
    clear 2>/dev/null || true

    print_header "CF Deployment Secrets Setup"

    check_gh_cli

    echo ""
    echo "Select the workflow you want to configure:"
    echo ""
    echo -e "  ${BOLD}1)${NC} Standard Deployment ${DIM}(deploy.yml)${NC}"
    echo "     Single CF foundation with Dev → Prod pipeline"
    echo "     8 secrets required"
    echo ""
    echo -e "  ${BOLD}2)${NC} Blue-Green Deployment ${DIM}(blue-green-deploy.yml)${NC}"
    echo "     Separate CF foundations, zero-downtime deploys"
    echo "     14 secrets required"
    echo ""
    echo -e "  ${BOLD}3)${NC} Both workflows"
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

    print_header "Setup Complete"

    echo -e "${BOLD}Next steps:${NC}"
    echo ""
    echo "1. Create the 'production' environment for manual approval:"
    echo -e "   ${DIM}Settings > Environments > New environment > 'production'${NC}"
    echo ""
    echo "2. Enable 'Required reviewers' on the production environment"
    echo ""
    echo "3. Verify your secrets in GitHub:"
    echo -e "   ${DIM}Settings > Secrets and variables > Actions${NC}"
    echo ""
}

main "$@"
