# cf-mcp-client Cloud Foundry Deployment

Automated deployment pipeline for [cf-mcp-client](https://github.com/cpage-pivotal/cf-mcp-client) to Cloud Foundry.

## How it works

1. A scheduled GitHub Action polls `cpage-pivotal/cf-mcp-client` for new releases every 6 hours.
2. When a new release is detected, the deploy job is queued and **waits for manual approval** via the `production` GitHub Environment.
3. Once approved, the workflow downloads the release JAR and manifest, then runs `cf push`.

You can also trigger a deployment manually from the **Actions** tab using "Run workflow" and optionally specifying a release tag.

## Required secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret | Description |
|--------|-------------|
| `CF_API` | Cloud Foundry API endpoint (e.g. `https://api.sys.example.com`) |
| `CF_USERNAME` | Cloud Foundry username |
| `CF_PASSWORD` | Cloud Foundry password |
| `CF_ORG` | Cloud Foundry organization |
| `CF_SPACE` | Cloud Foundry space |

## Environment setup

The `production` environment must be created in **Settings > Environments** with **Required reviewers** enabled. This enforces the approval gate before any deployment runs.
