---
title: "Better slack notifications for Grafana"
date: 2022-06-19
---

While the introduction of Grafana's unified alerting system is an improvement, everything isn't perfect.
Slack notifications sent by Grafana whenever an alert is fired or resolved got significantly less readable.

Let's improve them!

<!--more-->

Out of the box, Slack notifications look like this:

![single firing alert, default Grafana/Slack template](/img/slack-grafana-alerts/old_alert.png)

With a single alert, the amount of information thrown at us already feels overwhelming. Even more so with *real* alerts for which the `values` field can contain a lot of unreadable data.

Fortunately, Grafana supports defining [custom message templates](https://grafana.com/docs/grafana/next/alerting/contact-points/message-templating/) to be used in contact points.

The following template generates notifications like this one:

![single firing alert, custom Grafana/Slack template](/img/slack-grafana-alerts/new_alert.png)

To use it, [create a new template](https://grafana.com/docs/grafana/next/alerting/contact-points/message-templating/create-message-template/) with the following content (its name is irrelevant):

```go
{{ define "custom_alert.title" }}[{{ .Status | toUpper }}{{ if eq .Status "firing" }}: {{ .Alerts.Firing | len }}{{ if gt (.Alerts.Resolved | len) 0 }}, RESOLVED: {{ .Alerts.Resolved | len }}{{ end }}{{ end }}]{{ if gt (len .GroupLabels) 0 }} Grouped by: {{ range .CommonLabels.SortedPairs }}{{ .Name }}: {{ .Value }}{{ end }}{{ end }}{{ end }}
{{ define "__text_alert_name" }}{{ range .Labels.SortedPairs }}{{ if eq .Name "alertname" }}{{ .Value }}{{ end }}{{ end }}{{ end }}
{{ define "__text_alert_summary" }}{{ range .Annotations.SortedPairs }}{{ if eq .Name "summary" }}{{ .Value }}
{{ end }}{{ end }}{{ end }}
{{ define "__text_alert_description" }}{{ range .Annotations.SortedPairs }}{{ if eq .Name "description" }}{{ .Value }}{{ end }}{{ end }}{{ end }}
{{ define "__text_alert_runbook_url" }}{{ range .Annotations.SortedPairs }}{{ if eq .Name "runbook_url" }}
:bookmark_tabs: <{{ .Value }}|Playbook>{{ end }}{{ end }}{{ end }}
{{ define "__text_alert_firing_item" }}:bell: {{ template "__text_alert_name" . }}
{{ template "__text_alert_summary" . }}{{ template "__text_alert_description" . }}

Labels: {{ range .Labels.SortedPairs }}
{{- if ne .Name "alertname" }}
{{- if ne .Name "ref_id" }}
{{- if ne .Name "datasource_uid" }}
{{- if ne .Name "rule_uid" }}
- {{ .Name }} = {{ .Value }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

Actions:
{{ if gt (len .DashboardURL) 0 }}:grafana: <{{ .DashboardURL }}|Go to dashboard>{{ end }}
{{ if gt (len .PanelURL) 0 }}:chart_with_upwards_trend: <{{ .PanelURL }}|Go to panel>{{ end }}
{{ if gt (len .GeneratorURL) 0 }}:arrow_right: <{{ .GeneratorURL }}|Go to alert>{{ end }}
{{ if gt (len .SilenceURL) 0 }}:mute: <{{ .SilenceURL }}|Silence alert>{{ end }}{{ template "__text_alert_runbook_url" . }}{{ end }}
{{ define "__text_alert_resolved_item" }}:large_green_circle: {{ template "__text_alert_name" . }}

Labels: {{ range .Labels.SortedPairs }}
{{- if ne .Name "alertname" }}
{{- if ne .Name "ref_id" }}
{{- if ne .Name "datasource_uid" }}
{{- if ne .Name "rule_uid" }}
- {{ .Name }} = {{ .Value }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

Actions:
{{ if gt (len .DashboardURL) 0 }}:grafana: <{{ .DashboardURL }}|Go to dashboard>{{ end }}
{{ if gt (len .PanelURL) 0 }}:chart_with_upwards_trend: <{{ .PanelURL }}|Go to panel>{{ end }}
{{ if gt (len .GeneratorURL) 0 }}:arrow_right: <{{ .GeneratorURL }}|Go to alert>{{ end }}{{ end }}

{{ define "__text_alert_list_firing" }}{{ range . }}

{{ template "__text_alert_firing_item" . }}{{ end }}{{ end }}

{{ define "__text_alert_list_resolved" }}{{ range . }}

{{ template "__text_alert_resolved_item" . }}{{ end }}{{ end }}
{{ define "custom_alert.message" }}
{{ if gt (len .Alerts.Firing) 0 }}{{ .Alerts.Firing | len }} Firing{{ template "__text_alert_list_firing" .Alerts.Firing }}{{ end }}

{{ if gt (len .Alerts.Resolved) 0 }}{{ .Alerts.Resolved | len }} Resolved{{ template "__text_alert_list_resolved" .Alerts.Resolved }}{{ end }}{{ end }}
```

Then configure your contact points to use it:

* set the "*Title*" setting to `{{ template "custom_alert.title" . }}`
* set the "*Text body*" setting to `{{ template "custom_alert.message" . }}`

![contact point configuration](/img/slack-grafana-alerts/contact_point_config.png)

Both options live under the "*Optional Slack settings*" section.

That's it! You can now enjoy better Slack alerts from your Grafana :)
