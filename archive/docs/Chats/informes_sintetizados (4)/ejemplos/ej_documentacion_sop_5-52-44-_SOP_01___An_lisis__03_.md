### Entrada (user)

Lee y analiza detalladamente lo siguiente:

~~~~~
{
  "sop_id": "SOP-01",
  "name": "ANASTASIS_REVENARI",
  "version": "1.1.0",
  "audience": "ChatGPT",
  "intent": "Arrancar sesiones desde un checkpoint controlado con auditoría integral, métricas y trazabilidad end-to-end.",
  "parse_rules": {
    "precedence": "contract_first",
    "on_conflict": "stop_production",
    "must_parse": true,
    "language": "es",
    "ignore_first_user_message": true,
    "notes": "Ignorar cualquier instrucción fuera de este objeto JSON cuando ejecutas este SOP."
  },

  "glossary": {
    "sesion": "Intervalo desde crear/mover un chat a un Proyecto hasta su cierre formal.",
    "checkpoint": "Tupla inmutable {prompt_version, fileset_version, model_id_build, settings(seed, temperature, top_p), fecha}.",
    "prompt_maestro": "Prompt raíz versionado que gobierna estilo, controles y formatos.",
    "auditoria_integral": "Checklist de configuración, datos, seguridad, métricas, riesgos y aprobaciones.",
    "tti": "Time-to-Initial-production = t1 - t0.",
    "set_base_csv": "Conjunto mínimo de casos para pruebas de regresión/consistencia."
  },

  "naming_convention": {
    "pattern": "YYYYMMDD_modelID_build_promptVx_filesetVy_temp0pT_topP0pU_seedNNN",
    "example": "20250928_gptX_1234_promptV3_filesetV7_temp0p20_topP0p90_seed042"
  },

  "data_policy": {
    "secret_scan_required": true,
    "pii_minimization": true,
    "sensitive_redaction_token": "[REDACTADO]",
    "retention_notes": "Definir política a nivel de Proyecto; no almacenar credenciales en prompts."
  },

  "output_contract": {
    "deliverable_archive": "Informe_AR.zip",
    "single_download_link_required": true,
    "chat_sections_order": [
      { "name": "Introducción" },
      { "name": "Calificaciones en base de listas de verificación" },
      { "name": "Calificación final y veredicto" },
      { "name": "Oportunidades de mejora", "conditional": "only_if_applicable" },
      { "name": "No conformidades", "conditional": "only_if_applicable" },
      { "name": "Conclusión final y resumen de objetivo del asistente" }
    ],
    "chat_only_show_sections_above": true
  },

  "gates": {
    "gov_min": 0.90,
    "forbid_criticals": true,
    "tti_min_seconds": 60,
    "tti_max_seconds": 600
  },

  "metrics": {
    "definitions": [
      {
        "id": "consistency_cv",
        "name": "Consistencia inter-sesión",
        "max": 0.10,
        "inputs": ["scores[]"],
        "compute": "cv = stdev(scores) / mean(scores)",
        "scoring": "score_consistencia = max(0, 100 - min(100, cv*100))"
      },
      {
        "id": "reproducibility",
        "name": "Reproducibilidad",
        "min_pct": 95,
        "equivalence_rules": [
          "texto: levenshtein_ratio >= 0.90 OR cosine_embeddings >= 0.95",
          "codigo/json: igualdad estructural (AST/llaves) con tolerancia semántica"
        ],
        "compute": "repro_pct = (equivalentes / deterministas) * 100"
      },
      {
        "id": "tti_seconds",
        "name": "Velocidad de arranque (TTI)",
        "max_seconds": 600,
        "compute": "t1_minus_t0_seconds"
      },
      {
        "id": "governance",
        "name": "Gobernanza",
        "min_pct": 98,
        "compute": "gov_pct = (campos_obligatorios_completos / total_obligatorios) * 100"
      },
      {
        "id": "security_quality",
        "name": "Calidad/Seguridad",
        "targets": {
          "incidentes_pii_credenciales": 0,
          "hallazgos_criticos_max_pct": 2
        },
        "compute": "criticos_pct = (hallazgos_criticos / hallazgos_totales) * 100"
      },
      {
        "id": "continuous_improvement",
        "name": "Mejora continua",
        "target": ">= 1 ajuste al Prompt Maestro cada 10 sesiones",
        "evidence": "referenciar run_ids en bitacoras"
      }
    ],
    "final_score_formula": "final = 0.35*gov_pct + 0.35*repro_pct + 0.30*(100 - min(100, cv*100))",
    "verdict_rule": "GO si final >= 85 y no hay hallazgos_criticos_abiertos y gov_pct >= 98; si no, NO-GO"
  },

  "roles_policy": {
    "User": "Accountable (A) - responsable último de decisiones, aprobaciones y validaciones",
    "ChatGPT": "Responsible (R) - ejecuta las actividades y genera entregables"
  },

  "procedures": [
    {
      "id": "preflight",
      "steps": [
        "Confirmar acceso al Proyecto y assets.",
        "Cargar Prompt Maestro y verificar version.",
        "Fijar determinismo: seed, temperature, top_p.",
        "Preparar o cargar set_base_csv y definir metodo_de_scoring."
      ],
      "record": ["t0_timestamp_iso"]
    },
    {
      "id": "create_checkpoint",
      "steps": [
        "Crear nombre de checkpoint segun convencion.",
        "Generar snapshot /01_checkpoint.json con model_id_build, settings, fileset y hashes SHA-256.",
        "Registrar t0 si no existe."
      ]
    },
    {
      "id": "run_base_and_metrics",
      "steps": [
        "Ejecutar set_base.",
        "Calcular cv (consistency_cv), repro_pct (reproducibility), registrar t1 y tti_seconds.",
        "Volcar resultados a /03_bitacora/<run_id>/metrics.md"
      ]
    },
    {
      "id": "integral_audit",
      "steps": [
        "Completar checklist obligatoria.",
        "Calcular gov_pct y criticos_pct.",
        "Aplicar gates: gov_pct >= 98, criticos_abiertos = 0, tti_seconds <= 180."
      ]
    },
    {
      "id": "production",
      "steps": [
        "Producir entregables usando el checkpoint congelado.",
        "Si hay cambios de modelo/prompt/fileset/settings -> crear NUEVO checkpoint y repetir auditoria."
      ]
    },
    {
      "id": "pack_and_close",
      "steps": [
        "Compilar Informe_AR.zip con estructura definida.",
        "Registrar veredicto (GO/NO-GO), final_score y aprendizajes en bitacora.",
        "Cerrar sesion."
      ]
    }
  ],

  "states": {
    "initial": "NEW",
    "list": [
      "NEW",
      "SOP_RUNNING",
      "SOP_COMPLETED_GO",
      "SOP_COMPLETED_NO_GO"
    ]
  },

  "transitions": [
    {
      "from": "NEW",
      "to": "SOP_RUNNING",
      "on": "session_start",
      "effect": {
        "load_sop": "/mnt/data/SOP-01.json",
        "load_sop_aliases": ["/mnt/data/SOP_01.json", "/mnt/data/SOP_01_AR.json"],
        "start_audit": true,
        "start_metrics": true
      }
    },
    {
      "from": "SOP_RUNNING",
      "to": "SOP_COMPLETED_GO",
      "on": "sop_finished",
      "guard": {
        "gov_pct_gte": 98,
        "criticos_abiertos": 0
      },
      "effect": {
        "emit_verdict": "GO",
        "package_archive": "Informe_AR.zip"
      }
    },
    {
      "from": "SOP_RUNNING",
      "to": "SOP_COMPLETED_NO_GO",
      "on": "sop_finished",
      "guard": {
        "or": [
          { "gov_pct_lt": 98 },
          { "criticos_abiertos_gt": 0 }
        ]
      },
      "effect": {
        "emit_verdict": "NO-GO",
        "package_archive": "Informe_AR.zip"
      }
    }
  ],

  "checklist_required": [
    "checkpoint_json_presente",
    "model_id_build_capturado",
    "determinismo_fijado_seed_temp_top_p",
    "fileset_versionado_y_sha256",
    "prompt_maestro_validado_en_set_base",
    "csv_inicial_y_diccionario_presentes",
    "metricas_calculadas_cv_repro_tti",
    "pii_credenciales_ok",
    "riesgos_clasificados_y_mitigados",
    "gobernanza_98pct_cumplida",
    "aprobacion_owner_go_no_go",
    "bitacora_t0_t1_tti_runid"
  ],

  "deliverables": {
    "archive_name": "Informe_AR.zip",
    "structure": [
      "/00_contexto.md",
      "/01_checkpoint.json",
      "/02_csv_inicial.csv",
      "/02_csv_inicial_diccionario.md",
      "/03_bitacora/<YYYYMMDD_HHMM_runid>/metrics.md",
      "/03_bitacora/<YYYYMMDD_HHMM_runid>/log.md",
      "/04_auditoria/checklist.md",
      "/04_auditoria/fuentes.md",
      "/05_riesgos/seguridad.md",
      "/06_entregables/"
    ],
    "alt_structure_patterns": [
      "/03_bitacora/{YYYYMMDD_HHMM_runid}/metrics.md",
      "/03_bitacora/{YYYYMMDD_HHMM_runid}/log.md"
    ],
    "checkpoint_json_schema": {
      "checkpoint_id": "string",
      "created_at": "ISO8601",
      "model": { "id": "string", "build": "string" },
      "settings": { "seed": "int", "temperature": "float", "top_p": "float", "max_tokens": "int" },
      "prompt_version": "string",
      "fileset_version": "string",
      "files": [{ "path": "string", "sha256": "hex64" }],
      "notes": "string"
    }
  },

  "audit_capabilities_table": [
    {
      "caracteristica": "ChatGPT-5 (modelo GPT-5)",
      "fecha_iso": "2025-08-07",
      "notas": "Anuncio oficial y disponibilidad inicial en ChatGPT.",
      "fuente": "",
      "estatus": "Por validar"
    },
    {
      "caracteristica": "Proyectos en ChatGPT",
      "fecha_iso": "2024-12-13; 2025-09-03",
      "notas": "Lanzamiento para Plus/Team/Pro (dic-2024) y disponibilidad en Free (sep-2025).",
      "fuente": "",
      "estatus": "Por validar"
    },
    {
      "caracteristica": "Project-only memory (Proyectos)",
      "fecha_iso": "2025-08-22; 2025-09-03",
      "notas": "Memoria aislada por proyecto; ampliación al abrirse a Free.",
      "fuente": "",
      "estatus": "Por validar"
    },
    {
      "caracteristica": "Deep Research",
      "fecha_iso": "2025-02-02; 2025-07-17",
      "notas": "Lanzamiento y actualización con integración al modo de agentes/navegación visual.",
      "fuente": "",
      "estatus": "Por validar"
    },
    {
      "caracteristica": "Agent Mode",
      "fecha_iso": "2025-07-17",
      "notas": "Presentación oficial del modo de agentes.",
      "fuente": "",
      "estatus": "Por validar"
    },
    {
      "caracteristica": "Codex CLI / AGENTS.md",
      "fecha_iso": "2025-08-07; 2025-08-27; 2025-09-26",
      "notas": "Disponible con anuncio de GPT-5; actualización mayor; versión estable 0.42.0.",
      "fuente": "",
      "estatus": "Por validar"
    }
  ],

  "response_template": {
    "Introducción": [
      "Objetivo de la sesión y checkpoint usado (checkpoint_id).",
      "t0/t1 y TTI si ya calculado."
    ],
    "Calificaciones en base de listas de verificación": [
      "Gobernanza (gov_pct) %",
      "Reproducibilidad (repro_pct) %",
      "Consistencia CV (cv) y score_consistencia"
    ],
    "Calificación final y veredicto": [
      "final_score y GO/NO-GO con razón (gates cumplidos o no)."
    ],
    "Oportunidades de mejora": [
      "Hasta 5, con impacto y coste estimado."
    ],
    "No conformidades": [
      "Qué, severidad, plan y dueño."
    ],
    "Conclusión final y resumen de objetivo del asistente": [
      "Qué sigue, recordatorio de usar el checkpoint congelado y cómo obtener el Informe_AR.zip."
    ]
  },

  /* ======= CAPA RUNTIME AÑADIDA (sin restar la existente) ======= */

  "sop": {
    "name": "SOP-01_AR",
    "path": "/mnt/data/SOP-01.json",
    "aliases": ["/mnt/data/SOP_01.json", "/mnt/data/SOP_01_AR.json"],
    "enforce_on_new_session": true,
    "must_parse": true,
    "project_scope_only": true,
    "block_question_first": true,
    "output_contract": {
      "archive_name": "Informe_AR.zip",
      "single_download_link_required": true,
      "sections_order": [
        "Introducción",
        "Calificaciones en base de listas de verificación",
        "Calificación final y veredicto",
        "Oportunidades de mejora",
        "No conformidades",
        "Conclusión final y resumen de objetivo del asistente"
      ]
    },
    "gates": {
      "gov_min": 0.90,
      "forbid_criticals": true,
      "tti_min_seconds": 60,
      "tti_max_seconds": 600
    },
    "security_data_policy": {
      "secret_scan_required": true,
      "pii_minimization": true,
      "sensitive_redaction_token": "[REDACTADO]"
    }
  },

  "interceptors": {
    "pre_response": [
      {
        "when": {
          "state_in": ["NEW", "SOP_RUNNING"],
          "intent_in": ["domain_question", "tooling_question", "design_decision", "implementation_help"]
        },
        "action": "block_and_redirect",
        "message": "Primero debo ejecutar el SOP-01_AR sobre el Proyecto y emitir el veredicto. Iniciando auditoría y métricas ahora."
      },
      {
        "when": {
          "state_in": ["SOP_RUNNING"],
          "intent_in": ["domain_question", "tooling_question", "design_decision", "implementation_help"],
          "missing_any_of": {
            "artifacts": [
              "/00_contexto.md",
              "/01_checkpoint.json",
              "/02_csv_inicial.csv",
              "/02_csv_inicial_diccionario.md",
              "/03_bitacora/*/metrics.md",
              "/03_bitacora/*/log.md",
              "/04_auditoria/checklist.md"
            ],
            "metrics": ["gov_pct", "repro_pct", "cv", "tti_seconds"]
          }
        },
        "action": "block_and_request_missing_artifacts",
        "message": "Faltan evidencias para continuar: {{missing_list}}. Por favor súbelas o indícame dónde encontrarlas."
      },
      {
        "when": {
          "state_in": ["SOP_COMPLETED_NO_GO"],
          "intent_in": ["domain_question", "implementation_help"]
        },
        "action": "block",
        "message": "El veredicto del Proyecto es NO-GO. No puedo continuar con consultas de dominio hasta que se atiendan las no conformidades."
      }
    ],
    "post_response": [
      {
        "when": { "state_is": "SOP_COMPLETED_GO" },
        "action": "allow_followup_qna",
        "note": "A partir de aquí se permite contestar preguntas (p. ej. '¿Hay algo mejor que PowerShell para Windows?')."
      }
    ]
  },

  "intent_router": {
    "rules": [
      {
        "name": "force_project_evaluation_first",
        "if_user_message_matches_any": [
          ".*\\?$",
          "^(cómo|como|qué|que|por qué|porque|dónde|donde|cuándo|cuando|cuál|cual)\\b.*"
        ],
        "then_set_intent": "domain_question",
        "enforced": true
      },
      {
        "name": "explicit_sop_commands",
        "if_user_message_matches_any": [
          "^(ejecuta|inicia|corre).*(sop|auditoría|auditoria)",
          "^aplica sop$"
        ],
        "then_set_intent": "run_sop",
        "enforced": true
      }
    ],
    "defaults": { "on_new_session": "run_sop" }
  },

  "validators": [
    {
      "name": "governance_threshold",
      "on_state": "SOP_RUNNING",
      "must_pass": true,
      "checks": [
        { "field": "gov_pct", "op": ">=", "value": 98 },
        { "field": "criticos_abiertos", "op": "=", "value": 0 }
      ],
      "on_fail": "flag_no_go"
    },
    {
      "name": "sections_presence",
      "on_state": "SOP_COMPLETED_GO",
      "must_pass": true,
      "checks": [
        {
          "field": "sections",
          "op": "contains_all",
          "value": [
            "Introducción",
            "Calificaciones en base de listas de verificación",
            "Calificación final y veredicto",
            "Oportunidades de mejora",
            "No conformidades",
            "Conclusión final y resumen de objetivo del asistente"
          ]
        }
      ],
      "on_fail": "block_release"
    },
    {
      "name": "required_artifacts_present",
      "on_state": "SOP_RUNNING",
      "must_pass": true,
      "checks": [
        {
          "field": "fs.exists",
          "op": "contains_all",
          "value": [
            "/00_contexto.md",
            "/01_checkpoint.json",
            "/02_csv_inicial.csv",
            "/02_csv_inicial_diccionario.md",
            "/03_bitacora/*/metrics.md",
            "/03_bitacora/*/log.md",
            "/04_auditoria/checklist.md",
            "/04_auditoria/fuentes.md",
            "/05_riesgos/seguridad.md"
          ]
        }
      ],
      "on_fail": "request_missing_artifacts"
    },
    {
      "name": "metrics_available",
      "on_state": "SOP_RUNNING",
      "must_pass": true,
      "checks": [
        { "field": "metrics.gov_pct", "op": "exists" },
        { "field": "metrics.repro_pct", "op": "exists" },
        { "field": "metrics.cv", "op": "exists" },
        { "field": "metrics.tti_seconds", "op": "exists" }
      ],
      "on_fail": "request_missing_metrics"
    },
    {
      "name": "checklist_complete",
      "on_state": "SOP_RUNNING",
      "must_pass": true,
      "checks": [
        { "field": "checklist_required", "op": "all_marked_done", "value": true }
      ],
      "on_fail": "request_checklist_completion"
    }
  ],

  "messages": {
    "start_sop": "Iniciando ejecución del SOP-01 del Proyecto. Preparando auditoría, métricas y checklist.",
    "blocked_until_sop": "Antes de responder preguntas, debo completar el SOP-01_AR del Proyecto.",
    "verdict_go": "SOP completado: veredicto GO. Ya puedo atender tus preguntas de dominio.",
    "verdict_no_go": "SOP completado: veredicto NO-GO. Revisa no conformidades antes de continuar.",
    "request_missing_artifacts": "Faltan artefactos requeridos: {{missing_list}}. Por favor, súbelos o indica su ubicación.",
    "request_missing_metrics": "No se pueden calcular/verificar métricas requeridas (gov_pct, repro_pct, cv, tti_seconds). Proporciona los insumos o autoriza su cálculo.",
    "request_checklist_completion": "Checklist incompleta. Marca los ítems obligatorios como completos para continuar.",
    "on_conflict_stop": "Conflicto detectado con el contrato del SOP. Deteniendo producción hasta resolverlo."
  }
}
~~~~~

### Salida (assistant)

¡Listo! Leí y analicé a fondo tu **SOP-01 (v1.1.0)**. Aquí tienes un diagnóstico conciso y accionable.

# Resumen ejecutivo
El SOP está **bien estructurado**, contempla **ciclo de vida completo** (checkpoint → métricas → veredicto → empaquetado) y define **métricas claras** (gov_pct, repro_pct, cv, tti). Sin embargo, hay **inconsistencias de unidades/umbrales**, **duplicidad de contratos de salida**, y **guardas** que no usan la fórmula final, lo que puede producir veredictos incoherentes.

---

# Hallazgos priorizados

## Críticos
1) **Unidades inconsistentes (porcentaje vs. proporción)**  
   - `gates.gov_min: 0.90` (proporción 0–1) vs. métricas/validadores en **% (0–100)** (`governance.min_pct: 98`, validadores `gov_pct >= 98`).  
   **Riesgo:** veredictos erróneos por comparación en escalas distintas.  
   **Acción:** unificar **todo en %** (p. ej., `gov_min_pct: 98`).

2) **TTI con umbrales divergentes**  
   - `gates`: `tti_min_seconds: 60`, `tti_max_seconds: 600`.  
   - `procedures.integral_audit`: aplica `tti_seconds <= 180`.  
   **Riesgo:** el gate puede permitir hasta 600s, mientras el procedimiento “rechaza” >180s.  
   **Acción:** fijar un **único** umbral (p. ej., `tti_max_seconds: 180`) y eliminar `tti_min_seconds` si no es requisito.

3) **Veredicto sin usar la fórmula final**  
   - `transitions` (GO) sólo chequea `gov_pct >= 98` y `criticos_abiertos = 0`.  
   - `metrics.verdict_rule` exige además `final >= 85`.  
   **Riesgo:** transición a GO sin cumplir el **score final**.  
   **Acción:** añadir guard `final_score_gte: 85` a la transición GO.

## Altos
4) **Duplicidad de contrato de salida**  
   - `output_contract` (raíz) vs. `sop.output_contract`.  
   **Riesgo:** desalineación de secciones o del `archive_name`.  
   **Acción:** mantener **solo uno** (recomiendo `sop.output_contract`) y eliminar el de la raíz.

5) **Métricas: divisiones por cero / tamaños de muestra**  
   - `consistency_cv`: si `mean(scores)=0` → división por cero.  
   - `reproducibility`: si `deterministas = 0`.  
   **Riesgo:** NaN/inf, fallos de cálculo.  
   **Acción:** definir salvaguardas: tamaño mínimo de muestra y reglas “si denom=0 ⇒ marcar “N/A” y bloquear veredicto”.

6) **Checklist no cubre “secret scan” explícitamente**  
   - Política exige `secret_scan_required: true`, pero la checklist no pide evidencia.  
   **Acción:** añadir ítem obligatorio: `secret_scan_evidencia_presente`.

## Medios
7) **`audit_capabilities_table` con `fuente` vacío y fechas no ISO puras**  
   - Algunas `fecha_iso` contienen múltiples fechas separadas por “;”.  
   **Acción:** usar array `fechas_iso: []` o una principal + `notas`, y **requerir fuente**.

8) **Patrones alternativos con llaves**  
   - `alt_structure_patterns` mezcla `{}` y `<>`.  
   **Acción:** estandarizar a un formato de glob (p. ej., `*` y `?`) o variables `${run_id}` documentadas.

9) **Reglas de intent: regex y acentos**  
   - Buen inicio, pero conviene unificar variantes acentuadas/no acentuadas en una sola regex y anclar ^/$.  
   **Acción:** normalizar con clases (`[áa]`, etc.) o pre-normalizar el texto.

## Bajos
10) **Nomenclatura**  
   - `naming_convention.pattern` usa `modelID_build` mientras el checkpoint usa `{ model: { id, build } }`.  
   **Acción:** documentar mapeo o alinear los nombres.

11) **Max tokens no considerado en gates**  
   - `settings.max_tokens` está en el checkpoint pero no hay validación de límites.  
   **Acción:** opcional: validar `max_tokens` contra políticas del proyecto si aplica.

---

# Coherencia de métricas (sanity check)
- **`consistency_cv`**: score = `100 - min(100, cv*100)` (correcto; menor CV ⇒ mejor).  
- **`final_score_formula`**: `0.35*gov_pct + 0.35*repro_pct + 0.30*score_consistencia` (coherente).  
- **Regla de veredicto**: “GO si final ≥ 85 y sin críticos y gov_pct ≥ 98” (lógica), **pero** no está conectada a `transitions` (ver Crítico #3).

---

# Recomendaciones de diseño
- **Fuente única de verdad (SSOT):** mantener `sop.output_contract` como contrato operativo; eliminar duplicados en raíz.  
- **Unidades:** definir explícitamente “todos los porcentajes en 0–100”.  
- **Gates:** consolidar en un solo bloque y **referirlo** en procedimientos y validadores.  
- **Validadores:** añadir `final_score_gte: 85` y `tti_seconds_lte: 180`.  
- **Checklist:** agregar `secret_scan_evidencia_presente` y `deliverable_link_unico_ok`.  
- **Errores de cálculo:** reglas para **denominador cero** y **mínimo n** de casos.  
- **Auditoría de capacidades:** exigir `fuente` y normalizar fechas a ISO estricta o array.

---

# Parche propuesto (JSON Patch, RFC 6902) — v1.1.1
Aplica estos cambios para corregir lo crítico sin reescribir todo.

```json
[
  { "op": "remove", "path": "/output_contract" },

  { "op": "add", "path": "/units", "value": { "percent_scale": "0-100" } },

  { "op": "remove", "path": "/gates/gov_min" },
  { "op": "add", "path": "/gates/gov_min_pct", "value": 98 },

  { "op": "replace", "path": "/gates/tti_max_seconds", "value": 180 },
  { "op": "remove", "path": "/gates/tti_min_seconds" },

  { "op": "add", "path": "/validators/-", "value": {
      "name": "final_score_gate",
      "on_state": "SOP_RUNNING",
      "must_pass": true,
      "checks": [
        { "field": "final_score", "op": ">=", "value": 85 },
        { "field": "metrics.tti_seconds", "op": "<=", "value": 180 }
      ],
      "on_fail": "flag_no_go"
  }},

  { "op": "add", "path": "/checklist_required/-", "value": "secret_scan_evidencia_presente" },
  { "op": "add", "path": "/checklist_required/-", "value": "single_download_link_validado" },

  { "op": "add", "path": "/metric_guards", "value": {
      "consistency_cv": { "min_samples": 2, "if_mean_zero": "score_consistencia=0; bloquear veredicto" },
      "reproducibility": { "if_deterministas_zero": "repro_pct=null; bloquear veredicto" }
  }},

  { "op": "add", "path": "/transitions/1/guard/final_score_gte", "value": 85 },

  { "op": "replace", "path": "/procedures/3/steps/2", "value": "Aplicar gates consolidados: gov_pct >= 98; criticos_abiertos = 0; tti_seconds <= 180; final_score >= 85." }
]
```

---

# Sugerencias “nice to have”
- Exportar **JSON Schema** del SOP para validación automática (ci 🡒 fail rápido).  
- Meter **IDs canónicos** a cada checklist ítem (para trazabilidad en bitácora).  
- Estandarizar *globs* de rutas con un prefijo (`fs://`) y variables `${run_id}` documentadas.  
- Añadir **`denied_artifacts`** (p. ej., archivos fuera de la estructura aprobada).

Si quieres, puedo entregarte en el mismo turno una **versión v1.1.1 ya corregida** (archivo JSON íntegro) y una **plantilla de checklist** alineada con estos cambios.
