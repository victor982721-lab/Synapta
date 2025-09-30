```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "schema://postmortem_v5.report.schema.json",
  "title": "Postmortem v5 Report",
  "type": "object",
  "additionalProperties": false,
  "unevaluatedProperties": false,
  "required": ["schema_version", "profile", "metadata", "summary", "findings", "privacy"],
  "properties": {
    "schema_version": { "const": "5.0" },
    "profile": { "type": "string", "enum": ["local-fixed", "share-safe", "strict-ci"] },
    "consistency": {
      "type": "object",
      "additionalProperties": false,
      "required": ["k", "method", "agreement"],
      "properties": {
        "k": { "type": "integer", "enum": [1, 3, 5] },
        "method": { "type": "string", "enum": ["majority"] },
        "agreement": { "type": "number", "minimum": 0, "maximum": 1 }
      }
    },
    "metadata": {
      "type": "object",
      "additionalProperties": false,
      "required": ["script_name", "size_bytes", "sha256", "detected_encoding", "os", "ps_version", "analyzed_at_utc"],
      "properties": {
        "script_name": { "type": "string" },
        "size_bytes": { "type": "integer", "minimum": 0 },
        "sha256": { "type": "string", "pattern": "^[a-f0-9]{64}$" },
        "detected_encoding": { "type": "string" },
        "os": { "type": "string" },
        "ps_version": { "type": "string" },
        "working_directory": { "type": "string" },
        "analyzed_at_utc": { "type": "string", "format": "date-time" }
      }
    },
    "findings": {
      "type": "array",
      "minItems": 0,
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["id","rule","category","severity","confidence","verified","selfcheck","file","line","snippet","rationale","occurrences","suppressed"],
        "properties": {
          "id": { "type": "string", "pattern": "^[A-Z0-9-]+$" },
          "rule": { "$ref": "#/$defs/ruleId" },
          "category": { "type": "string", "enum": ["Seguridad","Robustez","Exactitud","Calidad","Privacidad"] },
          "severity": { "type": "string", "enum": ["Critical","High","Medium","Low"] },
          "confidence": { "type": "number", "minimum": 0, "maximum": 1 },
          "verified": { "type": "boolean" },
          "selfcheck": {
            "type": "object",
            "additionalProperties": false,
            "required": ["method","score","pass"],
            "properties": {
              "method": { "type": "string", "enum": ["QA","NLI"] },
              "score": { "type": "number", "minimum": 0, "maximum": 1 },
              "pass": { "type": "boolean" }
            }
          },
          "file": { "type": "string" },
          "line": { "type": "integer", "minimum": 1 },
          "column": { "type": ["integer","null"], "minimum": 1 },
          "snippet": { "type": "string" },
          "rationale": { "type": "string" },
          "fix_template": { "type": "string" },
          "fix_patch_hint": { "type": "string" },
          "occurrences": { "type": "integer", "minimum": 1 },
          "group_id": { "type": "string" },
          "suppressed": { "type": "boolean" }
        }
      }
    },
    "suppressions": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["rule","scope","reason"],
        "properties": {
          "rule": { "$ref": "#/$defs/ruleId" },
          "scope": { "type": "string", "enum": ["line","block","file"] },
          "reason": { "type": "string" },
          "lines": {
            "type": "array",
            "items": { "type": "integer", "minimum": 1 },
            "uniqueItems": true
          }
        }
      }
    },
    "summary": {
      "type": "object",
      "additionalProperties": false,
      "required": ["counts_por_categoria","severidad","score","top_risks","quick_wins"],
      "properties": {
        "counts_por_categoria": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "Seguridad": { "type": "integer", "minimum": 0 },
            "Robustez": { "type": "integer", "minimum": 0 },
            "Exactitud": { "type": "integer", "minimum": 0 },
            "Calidad": { "type": "integer", "minimum": 0 },
            "Privacidad": { "type": "integer", "minimum": 0 }
          }
        },
        "severidad": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "Critical": { "type": "integer", "minimum": 0 },
            "High": { "type": "integer", "minimum": 0 },
            "Medium": { "type": "integer", "minimum": 0 },
            "Low": { "type": "integer", "minimum": 0 }
          }
        },
        "score": { "type": "number", "minimum": 0, "maximum": 100 },
        "top_risks": { "type": "array", "items": { "type": "string" }, "maxItems": 50 },
        "quick_wins": { "type": "array", "items": { "type": "string" }, "maxItems": 50 }
      }
    },
    "privacy": {
      "type": "object",
      "additionalProperties": false,
      "required": ["redacted"],
      "properties": {
        "redacted": { "type": "boolean" },
        "redaction_map": { "type": "array", "items": { "type": "string" } }
      }
    }
  },
  "$defs": {
    "ruleId": {
      "type": "string",
      "enum": [
        "S01","S02","S03","S04","S05","S06",
        "R01","R02","R03","R06","R07","R08","R09","R10","R11","R12","R13","R14","R15","R16","R17",
        "A01","A02","A03","A04","A05",
        "Q01","Q02","Q03","Q04","Q05",
        "P01","P02"
      ]
    }
  }
}
```