{{/*
Expand the name of the chart.
*/}}
{{- define "pgbouncer.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pgbouncer.fullname" -}}
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
{{- define "pgbouncer.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pgbouncer.labels" -}}
helm.sh/chart: {{ include "pgbouncer.chart" . }}
{{ include "pgbouncer.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "pgbouncer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pgbouncer.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Generate userlist for PgBouncer authentication
*/}}
{{- define "pgbouncer.userlist" -}}
{{- $userlist := "" -}}
{{- if .Values.auth.externalUserlist.enabled -}}
  {{- if .Values.auth.externalUserlist.configMap -}}
    {{- $userlist = "EXTERNAL_CONFIGMAP" -}}
  {{- else if .Values.auth.externalUserlist.secret -}}
    {{- $userlist = "EXTERNAL_SECRET" -}}
  {{- end -}}
{{- else if .Values.auth.users -}}
  {{- range .Values.auth.users -}}
    {{- if .passwordSecret -}}
      {{- $userlist = printf "%s\"%s\" \"SCRAM_FROM_SECRET_%s_%s\"\n" $userlist .name .passwordSecret.name .passwordSecret.key -}}
    {{- else if .password -}}
      {{- $userlist = printf "%s\"%s\" \"SCRAM_%s\"\n" $userlist .name .password -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if not $userlist -}}
  {{- $userlist = .Values.auth.userlist -}}
{{- end -}}
{{- $userlist -}}
{{- end }}