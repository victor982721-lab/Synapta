### Entrada (user)

{"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": "The user provided the additional info about how they would like you to respond:\n```Tienes que revisar los correos EML que te enviaré y exponer la información más relevante de cada uno.\n\nUsa tablas o representaciones visuales profesionales para que la recopilación de datos sea más efectiva```"}

### Salida (assistant)

# -*- coding: utf-8 -*-
import pandas as pd
import re
from pathlib import Path
from typing import List, Tuple, Dict
from caas_jupyter_tools import display_dataframe_to_user

in_path = Path("/mnt/data/messages.csv")

# Robust CSV load with fallback encodings and separators
def robust_read_csv(path: Path) -> pd.DataFrame:
    last_err = None
    # Try common combos
    for enc in ["utf-8", "utf-8-sig", "latin-1"]:
        for sep in [",", ";", "\t", "|"]:
            try:
                df = pd.read_csv(path, encoding=enc, sep=sep, engine="python")
                # Heuristic: if only 1 column but it contains separators, keep trying
                if df.shape[1] == 1 and any(df.iloc[: min(10, len(df)), 0].astype(str).str.contains(r"[;,|\t]").fillna(False)):
                    continue
                return df
            except Exception as e:
                last_err = e
                continue
    raise last_err if last_err else RuntimeError("Failed to read CSV")

df = robust_read_csv(in_path)

# Normalize column names
df.columns = [str(c).strip() for c in df.columns]
lower_map = {c: c.lower() for c in df.columns}
df.columns = [c.lower() for c in df.columns]

# Known email-ish fields
candidate_text_cols = [c for c in df.columns if c in (
    "subject","asunto","body","cuerpo","message","mensaje","content","contenido",
    "from","de","sender","remitente","to","para","cc","bcc",
    "date","fecha","thread","hilo","conversation","conversación","participants","participantes",
    "attachments","adjuntos"
)]
# If nothing matched, just use all columns as text search
if not candidate_text_cols:
    candidate_text_cols = list(df.columns)

# Build a combined searchable text field
def combine_text(row) -> str:
    parts = []
    for c in candidate_text_cols:
        val = row.get(c, "")
        if pd.isna(val):
            continue
        parts.append(str(val))
    return " | ".join(parts)

text_series = df.apply(combine_text, axis=1).str.lower()

# Patterns
malpaso_pat = re.compile(r"\bmalpaso\b|\braudales\b|\bch\s*malpaso\b", re.IGNORECASE)

adicionales_terms = [
    r"\badicional(?:es)?\b",
    r"\bretrabaj(?:o|os)\b",
    r"\bmaniobra(?:s)?\b",
    r"\bextensi[oó]n(?:\s+de)?\s+tiempos?\b",
    r"\bampliaci[oó]n(?:\s+de)?\s+plazo\b",
    r"\bplazo\b",  # often used in context of extensions
    r"\blluvia\b",
    r"\bprecipitaci[oó]n\b",
    r"\binundaci[oó]n\b",
    r"\borden(?:es)?\s+de\s+cambio\b",
    r"\bcosto(?:s)?\s+adicional(?:es)?\b",
    r"\bvariaci[oó]n\s+de\s+alcance\b",
    r"\balcance\b",
    r"\bscope\b",
    r"\bDuskheim\b",  # as provided
]
adicionales_pat = re.compile("|".join(adicionales_terms), re.IGNORECASE)

# Negative filters to exclude overtime-only items
neg_terms = [
    r"\bhoras?\s+adicional(?:es)?\b",
    r"\bhoras?\s+extra\b",
    r"\btiempo\s+extra\b",
    r"\bovertime\b",
    r"\bhe\b"  # may be noisy, but keep for overtime shorthand
]
neg_pat = re.compile("|".join(neg_terms), re.IGNORECASE)

# Names to tag if present (not required for filter, used for metadata)
names = [
    r"no[ée]\s+ch[aá]vez",
    r"jos[eé]\s+luis\s+verduzco(\s+[\wáéíóúñ]+)?",
    r"samuel\s+rodr[ií]guez",
    r"francisco\s+inguanz?o",  # handle possible typos
]
names_pat = re.compile("|".join(names), re.IGNORECASE)

# Engineer Carlos Ruschke
ruschke_pat = re.compile(r"ruschke", re.IGNORECASE)

# Compute masks
has_malpaso = text_series.str.contains(malpaso_pat)
has_adicionales = text_series.str.contains(adicionales_pat)
has_neg = text_series.str.contains(neg_pat)
mask_core = has_malpaso & has_adicionales & ~has_neg

# Tagging
tag_lluvia = text_series.str.contains(r"\blluvia\b", re.IGNORECASE)
tag_maniobras = text_series.str.contains(r"\bmaniobra(?:s)?\b", re.IGNORECASE)
tag_retrabajo = text_series.str.contains(r"\bretrabaj(?:o|os)\b", re.IGNORECASE)
tag_extension = text_series.str.contains(r"\bextensi[oó]n(?:\s+de)?\s+tiempos?\b|\bampliaci[oó]n(?:\s+de)?\s+plazo\b|\bplazo\b", re.IGNORECASE)
tag_orden_cambio = text_series.str.contains(r"\borden(?:es)?\s+de\s+cambio\b", re.IGNORECASE)
tag_costos = text_series.str.contains(r"\bcosto(?:s)?\s+adicional(?:es)?\b", re.IGNORECASE)
tag_scope = text_series.str.contains(r"\balcance\b|\bscope\b|\bvariaci[oó]n\s+de\s+alcance\b", re.IGNORECASE)
tag_duskheim = text_series.str.contains(r"\bDuskheim\b", re.IGNORECASE)
tag_names = text_series.str.contains(names_pat)

# Ruschke: prefer recipient fields if present, else global
recipient_cols = [c for c in ["to","para","cc","bcc"] if c in df.columns]
if recipient_cols:
    rcpt_text = df[recipient_cols].astype(str).apply(lambda r: " | ".join(r.values), axis=1).str.lower()
    tag_ruschke = rcpt_text.str.contains(ruschke_pat)
else:
    tag_ruschke = text_series.str.contains(ruschke_pat)

tags_df = pd.DataFrame({
    "lluvia": tag_lluvia,
    "maniobras": tag_maniobras,
    "retrabajo": tag_retrabajo,
    "extension_plazo_tiempo": tag_extension,
    "orden_cambio": tag_orden_cambio,
    "costos_adicionales": tag_costos,
    "alcance_scope": tag_scope,
    "duskheim": tag_duskheim,
    "nombres_referencia": tag_names,
    "a_carlos_ruschke": tag_ruschke,
})

filtered = df.loc[mask_core].copy()
filtered_with_tags = pd.concat([filtered.reset_index(drop=True), tags_df.loc[mask_core].reset_index(drop=True)], axis=1)

# Save filtered CSV (full rows + tags)
out_path = Path("/mnt/data/malpaso_adicionales.csv")
filtered_with_tags.to_csv(out_path, index=False, encoding="utf-8-sig")

# Build a compact summary counts
summary = {
    "total_rows_csv": int(len(df)),
    "malpaso_adicionales_rows": int(mask_core.sum()),
    "a_carlos_ruschke_en_filtrados": int(tags_df.loc[mask_core, "a_carlos_ruschke"].sum()),
}
by_tag_counts = tags_df.loc[mask_core].sum().astype(int).rename("conteo").to_frame()

# Display to user: filtered preview and counts
try:
    display_dataframe_to_user("Correos filtrados: Malpaso - temas adicionales", filtered_with_tags)
except Exception as e:
    # If display tool not available, ignore
    pass

# Also save a compact tag counts CSV
tags_out = Path("/mnt/data/malpaso_adicionales_tag_counts.csv")
by_tag_counts.to_csv(tags_out, encoding="utf-8-sig")

summary, str(out_path), str(tags_out), {
    "columns_in_csv": list(df.columns),
    "text_columns_used": candidate_text_cols,
    "recipient_columns_used": recipient_cols,
}
