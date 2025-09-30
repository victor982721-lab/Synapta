```json
{
  "parse_rules": {
    "precedence": "contract_guardrails",
    "ignore_first_user_message": false,
    "notes": "Este SOP no sobreescribe políticas de sistema/seguridad; actúa bajo ellas."
  },
  "gates": {
    "gov_min_pct": 98,
    "forbid_criticals": true,
    "tti_max_seconds": 180
  },
  "metrics": {
    "final_score_formula": "final = 0.35*gov_pct + 0.35*repro_pct + 0.30*score_consistencia"
  },
  "transitions": [
    {
      "from": "SOP_RUNNING",
      "to": "SOP_COMPLETED_GO",
      "on": "sop_finished",
      "guard": {
        "gov_pct_gte": 98,
        "repro_pct_gte": 95,
        "tti_seconds_lte": 180,
        "criticos_abiertos": 0
      }
    },
    {
      "from": "SOP_RUNNING",
      "to": "SOP_COMPLETED_NO_GO",
      "on": "sop_finished",
      "guard": {
        "or": [
          { "gov_pct_lt": 98 },
          { "repro_pct_lt": 95 },
          { "tti_seconds_gt": 180 },
          { "criticos_abiertos_gt": 0 }
        ]
      }
    }
  ],
  "output_contract": {
    "deliverable_archive": "Informe_AR.zip",
    "chat_only_show_sections_above": true
  }
}
```