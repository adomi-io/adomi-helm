{{/*
Common labels stamped on every emitted capability CR. The Database reconciler
requires platform.adomi.io/client, supplied via .Values.platform.client.
*/}}
{{- define "platform.capabilityLabels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- with (.Values.platform | default dict).client }}
platform.adomi.io/client: {{ . | quote }}
{{- end }}
{{- end -}}

{{/*
platform.databases — emit one Database CR per entry in .Values.databases. Each:
  name (required), server (required), databaseName?, user?,
  credentials: { secret?, openbaoPath?, passwordKey? }
The capability controller provisions the database + role and, when
credentials.secret is set, delivers the password to that Secret in this
namespace. The workload reads it from env (explicit) — never inferred here.
*/}}
{{- define "platform.databases" -}}
{{- $chartInitSql := .Values.databaseInitSql | default list -}}
{{- range $db := .Values.databases | default list }}
---
apiVersion: platform.adomi.io/v1alpha1
kind: Database
metadata:
  name: {{ $db.name | required "databases[].name is required" }}
  labels:
    {{- include "platform.capabilityLabels" $ | nindent 4 }}
spec:
  serverRef:
    name: {{ $db.server | required "databases[].server is required" }}
  databaseName: {{ $db.databaseName | default $db.name | quote }}
  user: {{ $db.user | default $db.name | quote }}
  {{- with $db.credentials }}
  credentials:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- /* initSql = chart-level .Values.databaseInitSql (app-specific DB setup the
         chart knows it needs, e.g. auxiliary roles) + any per-entry $db.initSql.
         Runs as the server superuser after provisioning; keep it idempotent. */}}
  {{- $initSql := concat $chartInitSql ($db.initSql | default list) }}
  {{- with $initSql }}
  initSql:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
platform.sso — emit one SSOApplication CR per entry in .Values.sso. Each:
  name (required), protocol (oauth2|proxy), displayName?, redirectUris?,
  groups?  (Authentik group names the controller ensures exist — apps reference
           them in their SSO RBAC, e.g. role mapping),
  credentials: { secret? }   (the OIDC/proxy credential Secret name)
*/}}
{{- define "platform.sso" -}}
{{- range $sso := .Values.sso | default list }}
---
apiVersion: identity.adomi.io/v1alpha1
kind: SSOApplication
metadata:
  name: {{ $sso.name | required "sso[].name is required" }}
  labels:
    {{- include "platform.capabilityLabels" $ | nindent 4 }}
spec:
  protocol: {{ $sso.protocol | default "oauth2" | quote }}
  {{- with $sso.displayName }}
  displayName: {{ . | quote }}
  {{- end }}
  {{- with $sso.redirectUris }}
  redirectUris:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $sso.groups }}
  groups:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $sso.credentials }}
  credentials:
    targetSecret:
      name: {{ .secret | required "sso[].credentials.secret is required" }}
  {{- end }}
{{- end }}
{{- end -}}
