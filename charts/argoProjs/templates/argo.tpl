{{- define "argocdvals" }}
---
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  namespace: {{ .Values.general.namespace }}
  finalizers:
  - resources-finalizer.argocd.argoproj.io
{{- end -}}
