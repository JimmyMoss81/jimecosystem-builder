# JIMEcosystem — n8n Automation Portfolio

Two credential-free demonstration workflows designed for safe review and import into n8n.

These are portfolio demonstrations created with synthetic data. They are not claims of prior client work.

## Workflow 1 — Validated intake
Receives a webhook payload, validates required fields, normalizes data, creates a deterministic idempotency key, suppresses duplicates, and returns a structured result. A Google Sheets write step can be added only after test credentials are supplied.

## Workflow 2 — Supervised newsletter production
Receives a content brief, validates it, produces a deterministic newsletter package with UTM tracking, and requires human review before publication. It uses no paid AI API.

## Safety
- No credentials, tokens, API keys, or personal information.
- Workflows are inactive by default.
- External publication remains supervised.
- Test with the files in `samples/` before enabling writes.
