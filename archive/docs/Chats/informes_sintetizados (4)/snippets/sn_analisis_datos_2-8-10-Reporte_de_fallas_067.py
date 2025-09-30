def safe_block(text: str|None, fallback: str) -> str:
    return text if (text and len(text.strip())>0) else fallback

# Uso en cualquier f-string:
note_text = safe_block(note, "- Artefactos generados de forma idempotente y atómica.\n- .ps1 conserva el contenido original.")
return f"""
### Descargas
...
{note_text}
""".strip()