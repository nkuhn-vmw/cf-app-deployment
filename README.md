# cf-mcp-client Cloud Foundry Deployment

Automated deployment pipeline for [cf-mcp-client](https://github.com/cpage-pivotal/cf-mcp-client) to Cloud Foundry.

## Workflows

This repository contains two deployment workflows:

### 1. Standard Deployment (`deploy.yml`)

Simple deployment to Dev and Prod spaces within the same CF foundation.

### 2. Blue-Green Deployment (`blue-green-deploy.yml`)

Zero-downtime blue-green deployment supporting **different CF foundations** for nonprod and prod environments.

**Features:**
- Zero-downtime deployments using blue-green strategy
- Separate CF foundations for nonprod and prod
- Automatic health checks before route switching
- Automatic cleanup of old app instances
- Manual approval gate for production
- Generic configuration via secrets (works with any app)

**How Blue-Green Works:**
1. Deploy new version (green) without routes
2. Verify the green instance is healthy
3. Map production route to green instance
4. Unmap route from old (blue) instance
5. Stop and cleanup blue instance

---

## Standard Deployment (`deploy.yml`)

### How it works

1. A scheduled GitHub Action polls `cpage-pivotal/cf-mcp-client` for new releases every 6 hours.
2. When a new release is detected, the app is **automatically deployed to Dev**.
3. After Dev succeeds, the **Prod deployment waits for manual approval** via the `production` GitHub Environment.
4. Once approved, the workflow deploys to Prod and records the deployed version.

You can also trigger a deployment manually from the **Actions** tab using "Run workflow" and optionally specifying a release tag.

### Required secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret | Description |
|--------|-------------|
| `CF_API` | Cloud Foundry API endpoint (e.g. `https://api.sys.example.com`) |
| `CF_USERNAME` | Cloud Foundry username |
| `CF_PASSWORD` | Cloud Foundry password |
| `CF_ORG` | Cloud Foundry organization |
| `CF_DEV_SPACE` | Cloud Foundry dev space |
| `CF_PROD_SPACE` | Cloud Foundry production space |

---

## Blue-Green Deployment (`blue-green-deploy.yml`)

### How it works

1. Polls the upstream repository (configured via secret) for new releases every 6 hours.
2. Downloads release assets (JAR and manifest.yml).
3. **Nonprod deployment:** Deploys using blue-green strategy to the nonprod CF foundation.
4. **Prod deployment:** Waits for manual approval, then deploys using blue-green strategy to the prod CF foundation.
5. **Cleanup:** Removes old app instances after successful deployment.

### Required secrets

Configure these in **Settings > Secrets and variables > Actions**:

#### Application Configuration

| Secret | Description | Example |
|--------|-------------|---------|
| `APP_UPSTREAM_REPO` | GitHub repo to watch for releases | `owner/repo-name` |
| `APP_NAME` | Base application name | `my-app` |
| `APP_ROUTE_NONPROD` | Production route domain for nonprod | `my-app.apps.nonprod.example.com` |
| `APP_ROUTE_PROD` | Production route domain for prod | `my-app.apps.prod.example.com` |

#### Nonprod CF Foundation

| Secret | Description |
|--------|-------------|
| `CF_NONPROD_API` | Nonprod CF API endpoint (e.g. `https://api.sys.nonprod.example.com`) |
| `CF_NONPROD_USERNAME` | Nonprod CF username |
| `CF_NONPROD_PASSWORD` | Nonprod CF password |
| `CF_NONPROD_ORG` | Nonprod CF organization |
| `CF_NONPROD_SPACE` | Nonprod CF space |

#### Prod CF Foundation

| Secret | Description |
|--------|-------------|
| `CF_PROD_API` | Prod CF API endpoint (e.g. `https://api.sys.prod.example.com`) |
| `CF_PROD_USERNAME` | Prod CF username |
| `CF_PROD_PASSWORD` | Prod CF password |
| `CF_PROD_ORG` | Prod CF organization |
| `CF_PROD_SPACE` | Prod CF space |

### Manual workflow options

When triggering the workflow manually:

- **release_tag**: Specify a release tag (e.g., `v2.7.0`) to deploy a specific version
- **skip_nonprod**: Skip nonprod deployment and deploy directly to prod (requires approval)

---

## Environment setup

The `production` environment must be created in **Settings > Environments** with **Required reviewers** enabled. This enforces the approval gate before the Prod deployment runs.
