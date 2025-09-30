```yaml
model: GPT-5
temperature: 0.0
top_p: 1.0
frequency_penalty: 0
presence_penalty: 0
seed: 42          # o el que uses en tu checkpoint
style_guardrails:
  auto_translate: false
  auto_correct: false
  auto_summarize: false
  normalize_whitespace: false
  add_headings: false
output_wrappers:
  prepend_context: false
  append_disclaimer: false
```