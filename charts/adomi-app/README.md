# adomi-app

An **umbrella chart** that turns a small per-app *intent* into a complete, running
platform application:

- the **workload** — an `odoo`, `mailpit`, or `generic` subchart (the generic
  consumers), selected by `type`;
- its **database** — a CloudNativePG `Cluster` when `database.mode: cnpg`;
- its **single sign-on** — an Authentik `SSOApplication` (forward-auth `proxy` or
  native `oauth2`).

These are wired together **by convention on the release name**, so the intent stays
tiny and there is no value duplication. This chart is the declarative replacement
for the platform controller's `resolve` → `apptypes` → `cnpg` → `ssoapps` →
`integrations` Python: the same mapping, expressed as Helm templates that Argo CD,
CNPG, and the identity operator reconcile.

## The intent (`global.adomiApp`)

`global.adomiApp` is the entire app intent. Helm merges `global` into every
subchart, so the app subchart derives its DB host/secret, ingress host, TLS, and
forward-auth middleware from the same block the umbrella's own templates read.

```yaml
global:
  adomiApp:
    enabled: true
    type: odoo                 # odoo | mailpit | generic
    host: erp-prod-acme.example.com
    url:  https://erp-prod-acme.example.com
    ingressClassName: traefik
    tls:
      - secretName: wildcard-example-tls
        hosts: ["*.example.com"]
    database:
      mode: cnpg               # none | cnpg | external
      instances: 1
      storage: 10Gi
      name: app                # db + role name
      user: app
    sso:
      enabled: true
      protocol: proxy          # none | proxy | oauth2
      group: acme              # Authentik category (often the client slug)
      forwardAuthMiddleware: identity-forward-auth@kubernetescrd  # proxy
      redirectPaths: ["/oauth2/callback"]                         # oauth2
```

Then enable the matching subchart and set only its app-specific knobs:

```yaml
odoo:
  enabled: true
  image: { repository: ghcr.io/adomi-io/odoo, tag: "19.0" }
  odoo: { workers: 2 }
```

See `examples/` for odoo (cnpg + proxy), mailpit (no db), and generic (cnpg +
oauth2).

## Naming conventions (release name `R`, namespace `N`)

| Resource | Name |
|----------|------|
| CNPG Cluster | `R-db` |
| CNPG read-write host | `R-db-rw.N.svc.cluster.local` |
| CNPG credentials Secret | `R-db-app` (key `password`) |
| OAuth2 client-credentials Secret | `R-oidc` (`client-id` / `client-secret`) |
| SSOApplication | `R` (slug `N-R`) |

The app subcharts compute these same names from `.Release.Name`/`.Release.Namespace`
when `global.adomiApp.enabled` is true, which is how the workload finds its database
and SSO without being told.

## Secrets

No secrets live in this chart or in any committed values. The DB password is created
by CNPG (`R-db-app`); the OAuth2 client credentials are published into `R-oidc` by
the identity operator when it reconciles the `SSOApplication`. External databases
reference an existing Secret by name only.

## GitOps usage

Each app is one intent file in a customer's git repo
(`workspaces/<workspace>/apps/<app>.yaml`); an Argo CD `ApplicationSet` renders this
chart per file, computing `host`, `namespace`, and `release name` and passing the
intent as `valuesObject`. The customer repo therefore holds desired state only;
Argo CD + CNPG + the identity operator do the reconciling. (That ApplicationSet
lives in `kubernetes-provisioner` — added in the next phase.)
