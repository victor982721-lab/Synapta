```pseudo
input: gov_pct, repro_pct, cv, tti_seconds, criticos_abiertos

score_consistencia = 100 - min(100, cv*100)
final_score = 0.35*gov_pct + 0.35*repro_pct + 0.30*score_consistencia

gates_ok =
  (gov_pct >= 98) and
  (repro_pct >= 95) and
  (criticos_abiertos == 0) and
  (tti_seconds <= 180)

veredicto = "GO" if (final_score >= 85 and gates_ok) else "NO-GO"
```