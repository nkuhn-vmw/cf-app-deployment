# cf-app-deployment

Generic Cloud Foundry deployment pipeline with blue-green deployment support.

## Workflows

This repository contains three deployment workflows:

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

### 3. Multi-App GHE Deployment (`multi-app-deploy.yml`)

On-demand deployment of **two applications** to Cloud Foundry via **GitHub Enterprise Server**, with an email-based approval gate for production.

**Features:**
- On-demand trigger only (no scheduled polling)
- Deploys two separate applications in a single pipeline
- Manifest files stored in this repo (not pulled from upstream releases)
- GitHub Enterprise Server authentication for internal repositories
- Email approval gate — GHE emails configured reviewers before prod deployment
- Selective deployment — choose which apps to deploy per run
- Highly configurable via 20 secrets

---

## Standard Deployment (`deploy.yml`)

### How it works

1. A scheduled GitHub Action polls the upstream repository for new releases every 6 hours.
2. When a new release is detected, the app is **automatically deployed to Dev**.
3. After Dev succeeds, the **Prod deployment waits for manual approval** via the `production` GitHub Environment.
4. Once approved, the workflow deploys to Prod and records the deployed version.

You can also trigger a deployment manually from the **Actions** tab using "Run workflow" and optionally specifying a release tag.

### Required secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret | Description |
|--------|-------------|
| `APP_UPSTREAM_REPO` | GitHub repo to watch for releases (e.g. `owner/repo-name`) |
| `APP_NAME` | Base application name (e.g. `my-app`) |
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

## Multi-App GHE Deployment (`multi-app-deploy.yml`)

### How it works

1. Triggered manually from the **Actions** tab — specify a release tag and which apps to deploy.
2. The workflow authenticates to **GitHub Enterprise Server** using a PAT and validates the release exists.
3. Release artifacts are downloaded from the upstream GHE repo; manifest files are read from **this repository** (`manifests/app1/manifest.yml`, `manifests/app2/manifest.yml`).
4. Both applications are deployed to the **Nonprod** CF foundation.
5. A **deployment notification** is created via the GHE API, and the pipeline pauses at the `production` environment gate.
6. GHE sends an **email to configured reviewers** asking them to approve or reject the production deployment.
7. Once approved, both applications are deployed to the **Prod** CF foundation.
8. The deployed version is recorded in `.last-deployed-version`.

### Pipeline flow

```
workflow_dispatch (on-demand)
    │
    ▼
validate-and-prepare
    │  • Authenticate to GHE
    │  • Validate release exists
    │  • Download artifacts for App 1 & App 2
    │  • Copy manifests from repo
    │
    ▼
deploy-nonprod
    │  • Deploy App 1 to nonprod CF
    │  • Deploy App 2 to nonprod CF
    │
    ├──► notify-approval-required
    │       • Create GHE deployment notification
    │       • Reviewers receive email
    │
    ▼
deploy-prod  ◄── environment: production (approval gate)
    │  • Reviewer approves via GHE email link
    │  • Deploy App 1 to prod CF
    │  • Deploy App 2 to prod CF
    │  • Record deployed version
```

### Required secrets

Configure these in **Settings > Secrets and variables > Actions**:

#### GitHub Enterprise Server

| Secret | Description | Example |
|--------|-------------|---------|
| `GHE_HOST` | GHE server hostname | `github.mycompany.com` |
| `GHE_TOKEN` | Personal Access Token (scopes: `repo`, `read:org`, `workflow`) | `ghp_...` |

#### Application Configuration

| Secret | Description | Example |
|--------|-------------|---------|
| `APP_UPSTREAM_REPO` | GHE repo to pull releases from | `org/repo-name` |
| `APP1_NAME` | Application 1 base name | `my-api` |
| `APP1_MANIFEST_PATH` | Path to app1 manifest in this repo | `manifests/app1/manifest.yml` |
| `APP1_ARTIFACT_PATTERN` | Release asset filename pattern (`{version}` is replaced) | `my-api-{version}.jar` |
| `APP2_NAME` | Application 2 base name | `my-worker` |
| `APP2_MANIFEST_PATH` | Path to app2 manifest in this repo | `manifests/app2/manifest.yml` |
| `APP2_ARTIFACT_PATTERN` | Release asset filename pattern (`{version}` is replaced) | `my-worker-{version}.jar` |

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

#### Approval Gate

| Secret | Description | Example |
|--------|-------------|---------|
| `APPROVAL_REVIEWERS` | Comma-separated GHE usernames for notifications | `user1,user2,team-lead` |

### Manual workflow options

When triggering the workflow:

- **release_tag** (required): The release tag to deploy (e.g., `v2.7.0`)
- **deploy_app1**: Deploy Application 1 (default: true)
- **deploy_app2**: Deploy Application 2 (default: true)
- **skip_nonprod**: Skip nonprod and deploy directly to prod (still requires approval)

### Manifest files

Manifest files are stored in this repository under `manifests/`:

```
manifests/
├── app1/
│   └── manifest.yml    ← CF manifest for Application 1
└── app2/
    └── manifest.yml    ← CF manifest for Application 2
```

Edit these manifests to configure memory, instances, buildpacks, environment variables, and other CF settings for each application. The `cf push` command uses `-f manifest.yml` with the app name overridden by the pipeline.

### GHE authentication

The workflow authenticates to GitHub Enterprise Server using a Personal Access Token (PAT). The PAT requires these scopes:

- **repo** — Access to releases and repository content
- **read:org** — Read organization membership (for team-based approvals)
- **workflow** — Trigger and manage workflow runs

The `gh` CLI is configured at runtime via `gh auth login --hostname` to target the GHE instance. All API calls use the `GH_HOST` and `GH_TOKEN` environment variables.

### Email approval gate

The production deployment uses a GitHub **environment protection rule**:

1. Create a `production` environment in **Settings > Environments**
2. Enable **Required reviewers** and add the approving users/teams
3. When the pipeline reaches the `deploy-prod` job, GHE automatically sends an email to the configured reviewers
4. The email contains a link to approve or reject the deployment
5. Once approved, the production deployment proceeds

Additionally, the `notify-approval-required` job creates a GHE deployment event for broader visibility to repo watchers.

---

## Environment setup

The `production` environment must be created in **Settings > Environments** with **Required reviewers** enabled. This enforces the approval gate before the Prod deployment runs.
