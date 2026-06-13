{{/*
Expand the name of the chart.
*/}}
{{- define "odoo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "odoo.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "odoo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "odoo.labels" -}}
helm.sh/chart: {{ include "odoo.chart" . }}
{{ include "odoo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "odoo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "odoo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service account name
*/}}
{{- define "odoo.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "odoo.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image reference (tag defaults to the chart appVersion).
*/}}
{{- define "odoo.image" -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end }}

{{/*
Name of the bundled PostgreSQL Service / StatefulSet.
*/}}
{{- define "odoo.postgresql.fullname" -}}
{{- printf "%s-postgresql" (include "odoo.fullname" .) -}}
{{- end }}

{{/*
Resolve the database host. Falls back to the bundled PostgreSQL service when
no external host is set and the bundled database is enabled.
*/}}
{{- define "odoo.databaseHost" -}}
{{- if .Values.database.host -}}
{{- .Values.database.host -}}
{{- else if .Values.postgresql.enabled -}}
{{- include "odoo.postgresql.fullname" . -}}
{{- else -}}
{{- required "database.host is required when postgresql.enabled is false" .Values.database.host -}}
{{- end -}}
{{- end }}

{{/*
Selector labels for the bundled PostgreSQL.
*/}}
{{- define "odoo.postgresql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "odoo.name" . }}-postgresql
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: postgresql
{{- end }}

{{/*
Common labels for the bundled PostgreSQL.
*/}}
{{- define "odoo.postgresql.labels" -}}
helm.sh/chart: {{ include "odoo.chart" . }}
{{ include "odoo.postgresql.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Name of the Secret holding the DB password, and its key.
*/}}
{{- define "odoo.databaseSecretName" -}}
{{- if .Values.database.existingSecret -}}
{{- .Values.database.existingSecret -}}
{{- else -}}
{{- include "odoo.fullname" . -}}
{{- end -}}
{{- end }}
{{- define "odoo.databaseSecretKey" -}}
{{- if .Values.database.existingSecret -}}
{{- .Values.database.existingSecretKey -}}
{{- else -}}
db-password
{{- end -}}
{{- end }}

{{/*
Name of the Secret holding the Odoo admin/master password, and its key.
*/}}
{{- define "odoo.adminSecretName" -}}
{{- if .Values.adminPassword.existingSecret -}}
{{- .Values.adminPassword.existingSecret -}}
{{- else -}}
{{- include "odoo.fullname" . -}}
{{- end -}}
{{- end }}
{{- define "odoo.adminSecretKey" -}}
{{- if .Values.adminPassword.existingSecret -}}
{{- .Values.adminPassword.existingSecretKey -}}
{{- else -}}
admin-password
{{- end -}}
{{- end }}

{{/*
Name of the PVC used for the Odoo filestore.
*/}}
{{- define "odoo.pvcName" -}}
{{- if .Values.persistence.existingClaim -}}
{{- .Values.persistence.existingClaim -}}
{{- else -}}
{{- printf "%s-data" (include "odoo.fullname" .) -}}
{{- end -}}
{{- end }}