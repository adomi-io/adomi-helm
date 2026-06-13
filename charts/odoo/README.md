# Adomi - Odoo Helm Chart

This is a Helm chart for running [Adomi's Odoo image](https://github.com/adomi-io/odoo) on Kubernetes.

It runs the same nightly-built `ghcr.io/adomi-io/odoo` image you'd use locally with Docker Compose, connects it to PostgreSQL, keeps the filestore on a persistent volume, and exposes it through a Service and (optionally) an Ingress. Everything is driven by the same `ODOO_*` environment variables the image already understands, so anything you set in your Compose file maps straight onto your `values.yaml`.

> [!TIP]
> **New to this image?**
>
> Get comfortable with the image first. The [adomi-io/odoo](https://github.com/adomi-io/odoo) repo covers configuration, secret files, hooks, and building downstream images. This chart assumes you already know how the image works and just want to run it on a cluster.

> [!TIP]
> **Want to lower your license costs?**
>
> Try our [odoo-community-base](https://github.com/adomi-io/odoo-community-base) base image, which includes some helpful OCA packages and additional addons. Point the chart at it by setting:
> ```yaml
> image:
>   repository: ghcr.io/adomi-io/odoo-community-base
>   tag: latest
> ```

> [!NOTE]
>
> **The image this chart deploys**
>
> - [adomi-io/odoo](https://github.com/adomi-io/odoo)
>
> **Example downstream images**
>
> - [adomi-io/boilerplate-odoo](https://github.com/adomi-io/boilerplate-odoo)
> - [adomi-io/boilerplate-odoo-enterprise](https://github.com/adomi-io/boilerplate-odoo-enterprise)
> - [adomi-io/odoo-community-base](https://github.com/adomi-io/odoo-community-base)

# Highlights

This chart runs the exact image you develop against, configured the way you already configure it. You set `ODOO_*` values instead of baking a config file into a custom image, point at a database, and let the chart handle the Service, probes, persistence, and websocket routing. No new mental model on top of Odoo.

- 🐳 [**Same image as Compose**](https://github.com/adomi-io/odoo): Run the same `ghcr.io/adomi-io/odoo` image in production that you use locally.
- 🔧 [**Configured with `ODOO_*` variables**](#configuration): Set Odoo options through values instead of rebuilding the image.
- 🐘 [**Bundled or external Postgres**](#connecting-to-a-database): Ship a small PostgreSQL for a one-command start, or point at a managed database when you're ready.
- 💾 [**Persistent filestore**](#persistence): The Odoo data directory (`/volumes/data`) lives on a PersistentVolumeClaim, so attachments and sessions survive restarts.
- 📡 [**Websocket-aware Ingress**](#exposing-odoo): Route live chat and the bus to the gevent port without hand-writing Ingress rules.
- ❤️ **Built-in health checks**: Probes use Odoo's own `/web/health` endpoint, with a generous startup probe so first-boot module installs aren't killed.

# Getting started

> [!WARNING]
> This chart needs a Kubernetes cluster and [Helm](https://helm.sh/docs/intro/install/). If you just want Odoo on your laptop, the [Docker Compose setup](https://github.com/adomi-io/odoo) is the easier path.

Install the chart. There are no subcharts to fetch first, and the defaults give you Odoo plus a small in-cluster PostgreSQL:

```bash
helm install odoo ./charts/odoo
```

Wait for it to come up, then port-forward to reach the web UI:

```bash
kubectl rollout status deploy/odoo
kubectl port-forward svc/odoo 8069:8069
```

Open [http://127.0.0.1:8069](http://127.0.0.1:8069) and create your first database.

> [!NOTE]
> The database master password (the one Odoo asks for when creating or managing databases) defaults to `admin`. Change `adminPassword.value`, or point it at your own Secret with `adminPassword.existingSecret`, before you expose this anywhere.

# Update your image

Pull a newer nightly build by bumping the tag and upgrading. The chart tracks the Odoo major line through `image.tag`:

```bash
helm upgrade odoo ./charts/odoo --set image.tag=19.0
```

## Supported versions

| Odoo                                               | values.yaml                        |
|----------------------------------------------------|------------------------------------|
| [19.0](https://github.com/adomi-io/odoo/tree/19.0) | ```image: { tag: "19.0" }```       |

# Logging into the container

Need to jump into the running pod like you would via SSH? `kubectl exec` drops you right into the image's shell:

```bash
kubectl exec -it deploy/odoo -- /bin/bash
```

Handy for tailing logs, running `odoo-bin` by hand, or inspecting the generated config at `/volumes/config/_generated.conf`.

# Connecting to a database

By default the chart runs a single PostgreSQL pod alongside Odoo, kept on its own PersistentVolumeClaim. It's seeded straight from your `database.*` values, using the same user, password, and database name Odoo connects with, so there's nothing to keep in sync and `helm install` just works.

> [!NOTE]
> The bundled database is a convenience for getting started, demos, and small instances. For anything you care about, run a managed PostgreSQL (or your own HA setup) and point Odoo at it as shown below.

When you're ready for a managed database (RDS, Cloud SQL, a Postgres you already run), turn off the bundled one and point Odoo at yours:

```yaml
postgresql:
  enabled: false

database:
  host: my-postgres.example.com
  port: 5432
  name: odoo
  user: odoo
  password: ""              # leave empty and use existingSecret below
  existingSecret: odoo-db   # a Secret you created with a "db-password" key
  existingSecretKey: db-password
  sslmode: require
```

When you use `existingSecret`, the password is referenced straight from your Secret and never written into a rendered manifest.

# Configuration

Odoo is configured the same way as the underlying image: through `ODOO_*` environment variables. The chart surfaces the common ones as friendly values and lets you pass anything else through raw.

The everyday options live under `odoo:`:

```yaml
odoo:
  workers: 4          # ODOO_WORKERS, prefork multiprocessing server
  proxyMode: true     # ODOO_PROXY_MODE, trust X-Forwarded-* from your ingress
  listDb: false       # ODOO_LIST_DB, hide the database manager
  logLevel: info      # ODOO_LOG_LEVEL
```

Anything the image supports but the chart doesn't surface directly, set with `extraEnv`:

```yaml
extraEnv:
  - name: ODOO_LIMIT_TIME_CPU
    value: "120"
  - name: ODOO_DB_MAXCONN
    value: "64"
```

The full list of supported variables lives in the [image README](https://github.com/adomi-io/odoo), and the same names work here.

## Bring your own odoo.conf

Most things can be set with environment variables, but if you want full control, hand the image your own `odoo.conf`. Set `odooConf` and the chart mounts it at `/volumes/config/odoo.conf`, where the image runs it through `envsubst` and writes the result to `/volumes/config/_generated.conf` at startup:

```yaml
odooConf: |
  [options]
  workers = ${ODOO_WORKERS}
  limit_memory_hard = 2684354560
  server_wide_modules = base,web
```

Because it's processed with `envsubst`, you can still reference `${ODOO_*}` variables inside the file.

# Using Secret Files

The image promotes any file under `/run/secrets/` into an upper-cased environment variable, so a file named `ODOO_DB_PASSWORD` becomes the `ODOO_DB_PASSWORD` variable. Mount your own Secret with `extraVolumes` / `extraVolumeMounts` to keep using that pattern.

For the two passwords the chart manages (the Odoo master password and the database password), hand it an existing Secret instead of putting plaintext in your values:

```yaml
adminPassword:
  existingSecret: odoo-admin
  existingSecretKey: admin-password

database:
  existingSecret: odoo-db
  existingSecretKey: db-password
```

Create those Secrets however you normally do (sealed-secrets, external-secrets, `kubectl create secret`) and the chart will reference them.

# Exposing Odoo

By default the chart creates a `ClusterIP` Service on port `8069`. To put Odoo behind an Ingress, enable it and add your host:

```yaml
ingress:
  enabled: true
  className: traefik
  hosts:
    - host: erp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: erp-tls
      hosts:
        - erp.example.com
```

> [!WARNING]
> Set `odoo.proxyMode: true` whenever you put Odoo behind an Ingress. Otherwise Odoo won't trust the `X-Forwarded-*` headers from your ingress controller and generated URLs and rate limiting will be wrong.

Live chat and the bus run on the gevent port (`8072`), not the main HTTP port. Flip on `ingress.longpolling.enabled` and the chart adds `/websocket` and `/longpolling` rules that route to `8072` for you:

```yaml
ingress:
  enabled: true
  longpolling:
    enabled: true
```

# Workers and scaling

For real workloads, switch Odoo from threaded mode to the prefork multiprocessing server by setting `odoo.workers` above `0`, and give the pod resources to match:

```yaml
odoo:
  workers: 4

resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: "2"
    memory: 4Gi
```

A common starting point is roughly 1 CPU and ~1Gi of memory per 2 workers, plus headroom for the cron worker.

> [!NOTE]
> The filestore PVC defaults to `ReadWriteOnce`, which a single pod can mount. To run `replicaCount > 1` you'll need a `ReadWriteMany` storage class so every replica can share the filestore. Otherwise keep one replica and scale it up with workers.

There's also an optional HorizontalPodAutoscaler if your storage supports multiple replicas:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 80
```

# Persistence

Odoo's filestore, sessions, and outgoing mail queue live under `ODOO_DATA_DIR` (`/volumes/data`). The chart keeps that on a PersistentVolumeClaim so it survives pod restarts and upgrades:

```yaml
persistence:
  enabled: true
  size: 20Gi
  storageClass: fast-ssd
```

Already have a volume you want to reuse? Point the chart at it and it won't create a new one:

```yaml
persistence:
  existingClaim: my-odoo-filestore
```

# Adding addons

You've got two ways to get custom addons into the running pod.

Mount them at runtime with `extraVolumes` / `extraVolumeMounts`, which is handy when your addons live on their own PVC:

```yaml
extraVolumes:
  - name: extra-addons
    persistentVolumeClaim:
      claimName: my-addons
extraVolumeMounts:
  - name: extra-addons
    mountPath: /volumes/extra_addons
```

Or build a downstream image `FROM ghcr.io/adomi-io/odoo` with your addons baked in, push it, and set `image.repository` / `image.tag` to it.

> [!TIP]
> Check out our [Community Base Image](https://github.com/adomi-io/odoo-community-base) for an example of a downstream image which makes use of the `extra_addons` folder, and [boilerplate-odoo](https://github.com/adomi-io/boilerplate-odoo) for a project layout you can copy.

# Running Odoo Enterprise

You can even run Odoo Enterprise! Build a downstream image that copies the enterprise addons into `/volumes/enterprise` (see [boilerplate-odoo-enterprise](https://github.com/adomi-io/boilerplate-odoo-enterprise)), push it, then point this chart at that image:

```yaml
image:
  repository: ghcr.io/your-company/your-repo-name
  tag: latest
```

# Values reference

The values you'll reach for most often:

| Key | Default | Description |
| --- | --- | --- |
| `image.repository` | `ghcr.io/adomi-io/odoo` | Image to run. Swap for a downstream image to add addons. |
| `image.tag` | `""` (chart `appVersion`, `19.0`) | Image tag. |
| `replicaCount` | `1` | Number of Odoo pods (needs RWX storage to exceed 1). |
| `adminPassword.value` | `admin` | Odoo master password, stored in a Secret. |
| `adminPassword.existingSecret` | `""` | Use your own Secret for the master password instead. |
| `database.host` | `""` | External DB host. Leave empty to use the bundled PostgreSQL. |
| `database.port` / `name` / `user` / `password` | `5432` / `odoo` / `odoo` / `odoo` | DB connection details. |
| `database.existingSecret` | `""` | Existing Secret holding the DB password. |
| `database.sslmode` | `prefer` | PostgreSQL `sslmode`. |
| `odoo.workers` | `0` | Worker processes. `0` is threaded mode; `>0` enables prefork. |
| `odoo.proxyMode` | `false` | Trust `X-Forwarded-*` headers. Turn on behind an Ingress. |
| `odoo.listDb` | `true` | Show the database manager in the UI. Turn off in production. |
| `odoo.initModules` / `updateModules` | `""` | Modules to install / update on boot. |
| `persistence.enabled` | `true` | Keep the filestore on a PVC at `/volumes/data`. |
| `persistence.size` | `10Gi` | Filestore PVC size. |
| `persistence.existingClaim` | `""` | Reuse an existing PVC instead of creating one. |
| `service.type` | `ClusterIP` | Kubernetes Service type. |
| `ingress.enabled` | `false` | Create an Ingress. |
| `ingress.longpolling.enabled` | `false` | Route `/websocket` and `/longpolling` to port `8072`. |
| `autoscaling.enabled` | `false` | Enable a HorizontalPodAutoscaler. |
| `extraEnv` | `[]` | Extra raw env vars (any other `ODOO_*` option). |
| `odooConf` | `""` | Override the `odoo.conf` template mounted at `/volumes/config/odoo.conf`. |
| `postgresql.enabled` | `true` | Run the bundled PostgreSQL alongside Odoo. |
| `postgresql.image.tag` | `16` | PostgreSQL version for the bundled database. |
| `postgresql.persistence.size` | `8Gi` | PVC size for the bundled database. |

For everything else, the [`values.yaml`](./values.yaml) is commented end to end.

# Example values

Ready-to-use value files for the common setups live in [`examples/`](./examples). Install with `-f`:

```bash
helm install odoo ./charts/odoo -f charts/odoo/examples/production-values.yaml
```

| File | Setup |
| --- | --- |
| [`minimal-values.yaml`](./examples/minimal-values.yaml) | Bundled PostgreSQL, your own image and admin password. |
| [`ingress-values.yaml`](./examples/ingress-values.yaml) | Behind a Traefik Ingress with websockets and proxy mode. |
| [`external-database-values.yaml`](./examples/external-database-values.yaml) | External PostgreSQL, passwords from Secrets. |
| [`existing-secrets-values.yaml`](./examples/existing-secrets-values.yaml) | Bundled PostgreSQL, both passwords from Secrets. |
| [`production-values.yaml`](./examples/production-values.yaml) | External database, workers, resources, Ingress, sized storage. |

# License

For license details, see the [LICENSE](https://github.com/adomi-io/odoo/blob/master/LICENSE) file in the Odoo repository.
