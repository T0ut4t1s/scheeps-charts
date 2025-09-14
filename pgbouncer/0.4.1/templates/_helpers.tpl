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
Convert flat connection variables from questions.yaml to connections array
*/}}
{{- define "pgbouncer.connectionsFromQuestions" -}}
{{- $connections := list -}}
{{- $connectionCount := (.Values.auth.connectionCount | default 0 | int) -}}

{{/* Connection 1 */}}
{{- if and (.Values.auth.connection1Enabled | default false) (ge $connectionCount 1) -}}
{{- $conn1 := dict -}}
{{- $_ := set $conn1 "name" (.Values.auth.connection1Name | default "connection1") -}}
{{- $userSecret := dict -}}
{{- $_ := set $userSecret "name" (.Values.auth.connection1SecretName | default "service1-pg-secret") -}}
{{- $_ := set $userSecret "usernameKey" (.Values.auth.connection1UsernameKey | default "username") -}}
{{- $_ := set $userSecret "passwordKey" (.Values.auth.connection1PasswordKey | default "password") -}}
{{- $_ := set $userSecret "databaseKey" (.Values.auth.connection1DatabaseKey | default "database") -}}
{{- $_ := set $conn1 "userSecret" $userSecret -}}
{{- $connections = append $connections $conn1 -}}
{{- end -}}

{{/* Connection 2 */}}
{{- if and (.Values.auth.connection2Enabled | default false) (ge $connectionCount 2) -}}
{{- $conn2 := dict -}}
{{- $_ := set $conn2 "name" (.Values.auth.connection2Name | default "connection2") -}}
{{- $userSecret := dict -}}
{{- $_ := set $userSecret "name" (.Values.auth.connection2SecretName | default "service2-pg-secret") -}}
{{- $_ := set $userSecret "usernameKey" (.Values.auth.connection2UsernameKey | default "username") -}}
{{- $_ := set $userSecret "passwordKey" (.Values.auth.connection2PasswordKey | default "password") -}}
{{- $_ := set $userSecret "databaseKey" (.Values.auth.connection2DatabaseKey | default "database") -}}
{{- $_ := set $conn2 "userSecret" $userSecret -}}
{{- $connections = append $connections $conn2 -}}
{{- end -}}

{{/* Connection 3 */}}
{{- if and (.Values.auth.connection3Enabled | default false) (ge $connectionCount 3) -}}
{{- $conn3 := dict -}}
{{- $_ := set $conn3 "name" (.Values.auth.connection3Name | default "connection3") -}}
{{- $userSecret := dict -}}
{{- $_ := set $userSecret "name" (.Values.auth.connection3SecretName | default "service3-pg-secret") -}}
{{- $_ := set $userSecret "usernameKey" (.Values.auth.connection3UsernameKey | default "username") -}}
{{- $_ := set $userSecret "passwordKey" (.Values.auth.connection3PasswordKey | default "password") -}}
{{- $_ := set $userSecret "databaseKey" (.Values.auth.connection3DatabaseKey | default "database") -}}
{{- $_ := set $conn3 "userSecret" $userSecret -}}
{{- $connections = append $connections $conn3 -}}
{{- end -}}

{{/* Connection 4 */}}
{{- if and (.Values.auth.connection4Enabled | default false) (ge $connectionCount 4) -}}
{{- $conn4 := dict -}}
{{- $_ := set $conn4 "name" (.Values.auth.connection4Name | default "connection4") -}}
{{- $userSecret := dict -}}
{{- $_ := set $userSecret "name" (.Values.auth.connection4SecretName | default "service4-pg-secret") -}}
{{- $_ := set $userSecret "usernameKey" (.Values.auth.connection4UsernameKey | default "username") -}}
{{- $_ := set $userSecret "passwordKey" (.Values.auth.connection4PasswordKey | default "password") -}}
{{- $_ := set $userSecret "databaseKey" (.Values.auth.connection4DatabaseKey | default "database") -}}
{{- $_ := set $conn4 "userSecret" $userSecret -}}
{{- $connections = append $connections $conn4 -}}
{{- end -}}

{{- $connections | toYaml -}}
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