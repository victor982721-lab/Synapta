```json
{
  "timestamp_utc": "2025-09-29T12:00:00Z",
  "ui": {
    "project_active": {"value": true, "source": "[UI del usuario]"},
    "temporary_chat": {"value": false, "source": "[UI del usuario]"},
    "memory": {"state": "project-only", "source": "[UI del usuario]"},
    "ci_fields": {"count": 3, "approx_limit": 1500, "method": "visual", "source": "[UI del usuario]"}
  },
  "limits": {
    "custom_instructions_char_limit": {"approx": 1500, "status": "observed", "source": "[UI del usuario]"},
    "project_instructions_char_limit": {"approx": 8000, "status": "unverified", "source": "Pendiente"}
  },
  "plans": {
    "differences": [],
    "sources": []
  },
  "web_claims": [],
  "risks": [{"item": "Project Instructions limit", "status": "Pendiente", "next_step": "Medir con bloque 8200"}],
  "evidence_manifest": []
}
```