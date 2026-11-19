{{- define "teamcity.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- /*
The operator copies the labels of the TeamCity resource into the immutable
selectors of its StatefulSets, so the resource gets only these stable ones.
*/}}
{{- define "teamcity.nodeLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: teamcity-server
{{- end }}

{{- define "teamcity.proxyLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: proxy
{{- end }}

{{- define "teamcity.nodeDataDir" -}}
nodeDataDirVolumeClaim:
  name: {{ .root.Release.Name }}-{{ .node.name }}-data-dir
  volumeMount:
    name: node-data-dir
    mountPath: /node-data
  spec:
    accessModes: [ReadWriteOnce]
    {{- with .root.Values.nodeDataDir.storageClassName }}
    storageClassName: {{ . }}
    {{- end }}
    resources:
      requests:
        storage: {{ .root.Values.nodeDataDir.size }}
{{- end }}
