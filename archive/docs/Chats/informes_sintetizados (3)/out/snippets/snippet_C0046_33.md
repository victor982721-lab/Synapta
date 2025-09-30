```text
¿El bloque contiene ``` internas?
 ├─ Sí → Usa valla EXTERNA de TILDES (~~~~~) en el chat o en .md de ejemplo
 │        └─ ¿Además es archivo desde PowerShell?
 │             ├─ Sí → Here-string LITERAL (@'... '@) + (opcional) footer EXPANDIBLE ("@ ... "@)
 │             └─ No → Mantén valla de tildes en el .md
 └─ No → ¿Es archivo desde PowerShell?
          ├─ Sí → ¿Hay interpolación compleja?
          │        ├─ Sí → Here-string EXPANDIBLE ("@ ... "@) y escapa lo literal
          │        └─ No → Here-string LITERAL (@'... '@)
          └─ No → Usa ``` normales con lenguaje
```