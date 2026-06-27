# generic

A generic single-container web-application chart that follows the Adomi platform
**values contract**: an image, a Service, an optional Ingress, and an optional
database wired from an existing Secret. It is the catch-all "generic consumer" for
simple catalog apps that don't need a bespoke chart (uptime-kuma, vaultwarden, …).

## Values contract

| Key | Purpose |
|-----|---------|
| `image.repository` / `image.tag` | Container image (tag defaults to `appVersion`). |
| `service.port` | Port the container listens on; the Service and Ingress route here. |
| `ingress.enabled` / `ingress.hosts` / `ingress.className` / `ingress.tls` | Standard ingress. |
| `database.host` | When set, exposes `DB_HOST/PORT/NAME/USER/SSLMODE/PASSWORD` to the container. |
| `database.existingSecret` / `database.existingSecretKey` | Source the DB password from a Secret. |
| `extraEnv` / `extraEnvFrom` | Extra environment. |

## Platform mode

When deployed by the `adomi-app` umbrella chart, `global.adomiApp.enabled` is `true`
and the chart derives its database and ingress wiring **by convention** from the
release name (see `adomi-app`): the CNPG database (`<release>-db`), its credentials
Secret (`<release>-db-app`), the public host (`global.adomiApp.host`), TLS, ingress
class, and the Traefik forward-auth middleware when SSO runs in `proxy` mode. Run
standalone (no `global.adomiApp`) and the chart behaves like any other Helm chart.
