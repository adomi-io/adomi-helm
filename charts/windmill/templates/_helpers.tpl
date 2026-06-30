{{- define "windmill.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "windmill.fullname" -}}
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

{{- define "windmill.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "windmill.labels" -}}
helm.sh/chart: {{ include "windmill.chart" . }}
{{ include "windmill.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "windmill.selectorLabels" -}}
app.kubernetes.io/name: {{ include "windmill.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "windmill.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "windmill.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "windmill.image" -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end }}

{{- /* BASE_URL: explicit override, else https://<first ingress host>, else empty. */}}
{{- define "windmill.baseUrl" -}}
{{- if .Values.windmill.baseUrl -}}
{{- .Values.windmill.baseUrl -}}
{{- else if and .Values.ingress.enabled .Values.ingress.hosts -}}
{{- printf "https://%s" (first .Values.ingress.hosts).host -}}
{{- end -}}
{{- end }}
