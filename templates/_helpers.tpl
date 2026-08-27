{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "openldap.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "openldap.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Release.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "openldap.chart" -}}
{{- printf "%s-%s" .Release.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "openldap.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (printf "%s-foo" (include "common.names.fullname" .)) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Generate chart secret name
*/}}
{{- define "openldap.secretName" -}}
{{ default (include "openldap.fullname" .) .Values.global.existingSecret }}
{{- end -}}

{{/*
Renders a value that contains template.
Usage:
{{ include "openldap.tplValue" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "openldap.tplValue" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{/*
Return the proper Openldap image name
*/}}
{{- define "openldap.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "openldap.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.image ) "global" .Values.global) }}
{{- end -}}

{{/*
Return total replica count
*/}}
{{- define "openldap.replicaCount" -}}
{{- add (int .Values.replication.writeableReplicaCount) (int .Values.replication.readOnlyReplicaCount) -}}
{{- end -}}

{{/*
Return the proper base domain
*/}}
{{- define "global.baseDomain" -}}
{{- $bd := include "tmp.baseDomain" .}}
{{- printf "%s" $bd | trimSuffix "," -}}
{{- end }}

{{/*
tmp method to iterate through the ldapDomain
*/}}
{{- define "tmp.baseDomain" -}}
{{- if regexMatch ".*=.*" .Values.global.ldapDomain }}
{{- printf "%s" .Values.global.ldapDomain }}
{{- else }}
{{- $parts := split "." .Values.global.ldapDomain }}
  {{- range $index, $part := $parts }}
  {{- $index1 := $index | add 1 -}}
dc={{ $part }},
  {{- end}}
  {{- end -}}
{{- end -}}

{{/*
Return the server name
*/}}
{{- define "global.server" -}}
{{- printf "%s.%s" .Release.Name .Release.Namespace  -}}
{{- end -}}

{{/*
Return the admin bindDN
*/}}
{{- define "global.bindDN" -}}
{{- printf "cn=%s,%s" .Values.global.adminUser (include "global.baseDomain" .) -}}
{{- end -}}

{{/*
Return the ldaps port
*/}}
{{- define "global.ldapsPort" -}}
{{- printf "%d" .Values.global.sslLdapPort  -}}
{{- end -}}

{{/*
Return the ldap port
*/}}
{{- define "global.ldapPort" -}}
{{- printf "%d" .Values.global.ldapPort  -}}
{{- end -}}