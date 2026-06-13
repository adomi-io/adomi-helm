# Adomi Helm Charts

This is the Adomi Helm repository, a collection of Helm charts for deploying Adomi software on Kubernetes.

The charts follow the same conventions. Sensible defaults bring a chart up with a single `helm install`, a documented `values.yaml` covers everything else, and the configuration mirrors the images each chart runs.

> [!TIP]
> **Here for the Odoo chart?**
>
> It lives in [`charts/odoo`](./charts/odoo). That README walks through the database, ingress, persistence, workers, and pointing it at your own image.

# Charts

| Chart | What it runs |
| --- | --- |
| [odoo](./charts/odoo) | The [adomi-io/odoo](https://github.com/adomi-io/odoo) image, with an optional in-cluster PostgreSQL. |

Each chart lives in its own folder under `charts/` with its own README and `Chart.yaml`.

# Using a chart

Clone the repo and install any chart straight from its path:

```bash
git clone https://github.com/adomi-io/adomi-helm.git
cd adomi-helm
helm install odoo ./charts/odoo
```

Override whatever you need with your own values file:

```bash
helm install odoo ./charts/odoo -f my-values.yaml
```

Each chart's README documents the values it understands, so start there.

# Repository layout

```text
charts/
  odoo/        # Odoo
```

Every chart is self-contained under `charts/<name>` and versioned on its own.

# Adding a chart

New charts go in their own folder under `charts/`:

```bash
helm create charts/my-chart
```

Keep it consistent with the others. Document every value in `values.yaml`, write the README in the [Adomi voice](./charts/odoo/README.md) (workflow-first, real commands, real paths), and bump the chart `version` on every change.

# Related repositories

- [adomi-io/odoo](https://github.com/adomi-io/odoo): the Odoo image the chart deploys
- [adomi-io/odoo-community-base](https://github.com/adomi-io/odoo-community-base): base image with OCA packages and extra addons
- [adomi-io/boilerplate-odoo](https://github.com/adomi-io/boilerplate-odoo): starter project for building your own image
- [adomi-io/boilerplate-odoo-enterprise](https://github.com/adomi-io/boilerplate-odoo-enterprise): the same, with Odoo Enterprise

# License

See each chart and its upstream image repository for license details.
