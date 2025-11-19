# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Características principales

* Artefactos reutilizables: {{KEY_ARTEFACTS}}.
* Dependencias Core: {{CORE_DEPENDENCIES}}.
* Alcance excluido: {{OUT_OF_SCOPE}}.

## Cómo usar este proyecto

1. **Compilación / instalación:** {{BUILD_STEPS}}.
2. **Ejecución:** {{RUN_STEPS}}.
3. **Pruebas:** {{TEST_STEPS}}.
4. La documentación completa se encuentra en `docs/` y las tablas normativas en `csv/`.

## Estructura obligatoria

```
{{PROJECT_NAME}}/
├── AGENTS.md
├── README.md
├── {{PROJECT_NAME}}.csproj | main.ps1
├── docs/
│   ├── solicitud_de_artefactos.md
│   ├── filemap_ascii.txt
│   ├── table_hierarchy.json
│   ├── plan.md
│   └── bitacora.md
├── csv/
│   ├── modules.csv
│   └── artefacts.csv
├── Scripts/
├── src/
└── tests/
```

## Referencias

* Política cultural y de calidad – Ecosistema Neurologic.
* AGENTS general y `AGENTS.md` de este proyecto.
* `Sandbox/.Codex/Procedimiento_de_solicitud_de_artefactos.md`.
