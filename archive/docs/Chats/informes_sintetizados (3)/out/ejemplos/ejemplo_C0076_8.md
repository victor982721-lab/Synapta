```

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
        "evidence": "referenciar run_ids en bitácoras"
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
    "checkpoint_json_schema": {
      "checkpoint_id": "string",
      "created_at": "ISO8601",
      "model": {"id": "string", "build": "string"},
      "settings": {"seed": "int", "temperature": "float", "top_p": "float", "max_tokens": "int"},
      "prompt_version": "string",
      "fileset_version": "string",
      "files": [{"path": "string", "sha256": "hex64"}],
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
  }
}
```