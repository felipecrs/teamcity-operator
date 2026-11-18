{{/*
Expand the name of the chart.
*/}}
{{- define "teamcity.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "teamcity.fullname" -}}
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
{{- define "teamcity.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "teamcity.labels" -}}
helm.sh/chart: {{ include "teamcity.chart" . }}
app.kubernetes.io/name: {{ include "teamcity.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels. The operator copies the labels of the TeamCity resource into
the immutable selectors of its StatefulSets, so that resource only carries
these, which never change. The operator labels the pods with
app.kubernetes.io/component=teamcity-server too, which keeps other pods of the
release, like the test, out of the Services.
*/}}
{{- define "teamcity.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: teamcity-server
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "teamcity.serviceAccountName" -}}
{{- default (include "teamcity.fullname" .) .Values.serviceAccount.name }}
{{- end }}

{{/*
The TeamCity server image
*/}}
{{- define "teamcity.image" -}}
{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end }}
