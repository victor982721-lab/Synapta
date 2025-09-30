```json
{
  "quality_gates": {
    "pssa": { "fail_on": ["Error","Warning"] },
    "complexity": { "max": 10 },
    "help_coverage": { "min_pct": 90 },
    "signed_files": { "required": false }
  },
  "checks": {
    "shouldprocess": true,
    "strict_mode": { "enforce": true },
    "path_hygiene": { "ban_set_location": true },
    "streams": { "flag_write_host": true },
    "error_handling": { "require_try_catch": true, "enforce_erroraction_stop": true },
    "manifest_export": true,
    "help": { "require_on_exports": true },
    "security": { "ban_invoke_expression": true },
    "ast_scan": true,
    "portability": true
  },
  "dependencies": {
    "psresources": [{ "name": "PSScriptAnalyzer", "version": "latest" }]
  },
  "artifacts": { "sarif": { "emit": true } }
}
```