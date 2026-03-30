# Kévin Gomez – Posts
{{ $pages := where site.RegularPages "Type" "in" site.Params.mainSections }}
{{- range $pages }}
=> {{ strings.TrimPrefix "/posts" .Path }}.gmi	{{ .Date | time.Format "2006-01-02" }} – {{ .Title }}
{{- end }}
