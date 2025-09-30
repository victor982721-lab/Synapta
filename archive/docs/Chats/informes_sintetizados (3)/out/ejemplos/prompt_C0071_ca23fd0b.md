```text
{
  "schema_version": "5.0",
  "profile": "local-fixed",
  "privacy": { "redacted": true, "allow_private_paths_in_output": false },
  "consistency": { "k": 3, "method": "majority" },
  "verification": { "cove_enabled": true, "cove_max_questions_per_finding": 3, "selfcheck_method": "QA", "selfcheck_threshold": 0.6 },
  "guards": { "deterministic": true, "reject_on_schema_violation": true, "ignore_inline_instructions_in_sources": true, "max_findings": 2000 },
  "env": { "os": "Windows 10 Pro 10.0.19045", "ps_version": "7.5.3", "user": "VictorFabianVeraVill", "machine": "DESKTOP-K6RBEHS", "working_directory": "/mnt/data" },
  "inputs": [
    { "path": "/mnt/data/PS-Env-Audit-CLEAN.ps1" },
    {
      "file_name": "Generador_HTML.ps1",
      "fragments": [
        { "seq": 1, "content": "param(...)" },
        { "seq": 2, "content": "# resto del script ..." }
      ]
    }
  ],
  "rules": {
    "enable": ["S01","S02","S03","S04","S05","S06","R01","R02","R03","R06","R07","R08","R09","R10","R11","R12","R13","R14","R15","R16","R17","A01","A02","A03","A04","A05","Q01","Q02","Q03","Q04","Q05","P01","P02"],
    "disable": []
  },
  "output": {
    "emit": ["snapshot","json","summary"],
    "json_path_hint": "/mnt/data/postmortem_v5/PS-Env-Audit-CLEAN.postmortem_v5.json",
    "snapshot_dir_hint": "/mnt/data/postmortem_v5/snapshots",
    "include_redaction_map": true
  },
  "analysis_options": {
    "snippet_context_lines": 3,
    "max_lines_per_snippet": 3,
    "encoding_assumed": "utf-8"
  }
}
```