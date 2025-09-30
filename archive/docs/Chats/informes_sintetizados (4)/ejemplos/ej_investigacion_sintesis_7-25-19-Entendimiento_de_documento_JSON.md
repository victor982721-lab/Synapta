### Entrada (user)

{"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": ""}

### Salida (assistant)

Es un **JSON Schema** que define el formato exacto de una “solicitud Postmortem v5” para validar entradas, opciones y salidas de un análisis de scripts PowerShell en tu entorno, con política estricta de propiedades y controles de verificación. fileciteturn0file0

Resumen utilizable:
- **Tipo y rigor:** objeto con `additionalProperties:false` y `unevaluatedProperties:false`. Campos obligatorios: `schema_version`, `profile`, `privacy`, `inputs`, `rules`, `output`. `schema_version` debe ser `"5.0"`. fileciteturn0file0
- **Perfiles y privacidad:** `profile` ∈ {`local-fixed`,`share-safe`,`strict-ci`}. Si `profile=share-safe`, `privacy.redacted` debe ser `true`. `allow_private_paths_in_output` por defecto `false`. fileciteturn0file0
- **Consistencia:** repetición controlada con mayoría; `k` ∈ {1,3,5}, por defecto `1`. fileciteturn0file0
- **Verificación:** Cove activo por defecto; hasta 2–4 preguntas por hallazgo (defecto 3); auto-chequeo `selfcheck_method` ∈ {`QA`,`NLI`} con umbral 0.6. fileciteturn0file0
- **Guardas:** ejecución determinista, rechazo si hay violaciones de esquema, ignorar instrucciones inline en fuentes, y límite de hallazgos (defecto 2000). fileciteturn0file0
- **Entorno fijado:** `os="Windows 10 Pro 10.0.19045"`, `ps_version="7.5.3"`, `user="VictorFabianVeraVill"`, `machine="DESKTOP-K6RBEHS"`, `working_directory` debe estar bajo `/mnt/data`. fileciteturn0file0
- **Entradas (`inputs`):** 1–64 elementos. Dos modos excluyentes por elemento:  
  1) `path` que cumpla `^/mnt/data/.+\.ps1$`, o  
  2) ensamblado por `fragments` + `file_name` (`*.ps1`), donde cada fragmento tiene `seq` ≥1 y `content` no vacío. fileciteturn0file0
- **Reglas (`rules`):** `enable` obligatorio con IDs únicos de un conjunto cerrado: `S01..S06`, `R01..R17` (excepto faltantes), `A01..A05`, `Q01..Q05`, `P01..P02`. `disable` opcional con los mismos IDs. fileciteturn0file0
- **Salida (`output`):** `emit` ⊆ {`snapshot`,`json`,`summary`} con al menos uno. Si incluye `json`, entonces es obligatorio `json_path_hint` bajo `/mnt/data/postmortem_v5/*.json`. `snapshot_dir_hint` debe apuntar a `/mnt/data/postmortem_v5` o subcarpeta `/snapshots`. `include_redaction_map` por defecto `true`. fileciteturn0file0
- **Opciones de análisis:** contexto por snippet 1–5 líneas (defecto 3), máx. líneas por snippet 1–20 (defecto 3), codificación `utf-8` o `utf-8-nobom` (defecto `utf-8`). fileciteturn0file0
- **Reglas condicionales clave:**  
  - Si `profile=share-safe` ⇒ `privacy.redacted=true`.  
  - Si `emit` contiene `json` ⇒ `json_path_hint` es obligatorio. fileciteturn0file0

En síntesis: el documento fija un contrato rígido para pedir un postmortem v5, define cómo entregar archivos fuente `.ps1` o fragmentos, qué reglas activar/desactivar, y qué artefactos de salida producir, todo bajo tu entorno Windows/PS7 predefinido. fileciteturn0file0
