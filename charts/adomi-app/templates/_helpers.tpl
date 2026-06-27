{{/*
The intent block (global.adomiApp). Every umbrella template reads from here.
*/}}
{{- define "adomiApp.intent" -}}
{{- .Values.global.adomiApp | default dict | toYaml -}}
{{- end }}

{{/* CNPG Cluster name for this app (convention shared with the app subcharts). */}}
{{- define "adomiApp.dbCluster" -}}
{{- printf "%s-db" .Release.Name -}}
{{- end }}

{{/* OAuth2 client-credentials Secret name (when sso.protocol=oauth2). */}}
{{- define "adomiApp.oidcSecret" -}}
{{- $sso := (.Values.global.adomiApp | default dict).sso | default dict -}}
{{- $sso.secret | default (printf "%s-oidc" .Release.Name) -}}
{{- end }}

{{/* Common labels stamped on the platform resources this chart owns. */}}
{{- define "adomiApp.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: adomi-platform
platform.adomi.io/application: {{ .Release.Name }}
{{- end }}

{{/*
Fail fast on an inconsistent intent: the enabled subchart must match the type, and
a usable host must be present.
*/}}
{{- define "adomiApp.validate" -}}
{{- $i := .Values.global.adomiApp | default dict -}}
{{- $type := $i.type | default "" -}}
{{- if not (has $type (list "odoo" "mailpit" "generic")) -}}
{{- fail (printf "global.adomiApp.type must be one of odoo|mailpit|generic (got %q)" $type) -}}
{{- end -}}
{{- if not (index .Values $type "enabled") -}}
{{- fail (printf "global.adomiApp.type is %q but the %q subchart is not enabled (set %s.enabled=true)" $type $type $type) -}}
{{- end -}}
{{- range $other := (without (list "odoo" "mailpit" "generic") $type) -}}
{{- if (index $.Values $other "enabled") -}}
{{- fail (printf "type is %q but subchart %q is also enabled; enable exactly one" $type $other) -}}
{{- end -}}
{{- end -}}
{{- if not $i.host -}}
{{- fail "global.adomiApp.host is required" -}}
{{- end -}}
{{- end }}
