# Kévin Gomez – Posts
{{ $pages := where site.RegularPages "Type" "in" site.Params.mainSections }}
{{- range $pages }}
=> .{{ .Path }}.gmi	{{ .Date | time.Format "2006-01-02" }} – {{ .Title }}
{{- end }}
