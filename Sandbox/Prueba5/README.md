# Prueba5

Proyecto del ecosistema Neurologic que produce artefactos reutilizables y herramientas.

## Características principales

* Artefactos reutilizables: Pendiente de definir.
* Dependencias Core: Core.FileSystem; Core.Indexing; Core.Logging.
* Alcance excluido: Detallar exclusiones.

## Cómo usar este proyecto

1. **Compilación / instalación:** dotnet build .\{{PROJECT_NAME}}.csproj -c Release.
2. **Ejecución:** .\bin\Release\net8.0\{{PROJECT_NAME}}.exe.
3. **Pruebas:** dotnet test.
4. La documentación completa se encuentra en `docs/` y las tablas normativas en `csv/`.

## Estructura obligatoria

```
Prueba5/
├── AGENTS.md
├── README.md
├── Prueba5.csproj | main.ps1
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

