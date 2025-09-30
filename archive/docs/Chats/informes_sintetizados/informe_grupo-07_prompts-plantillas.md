# Prompts/plantillas

## Resumen ejecutivo

Se analizaron 47 conversaciones clasificadas en el grupo **prompts/plantillas**.
Las conversaciones destacan principalmente por los siguientes elementos:
- **steps** presente en 95.7% de los casos.
- **examples** presente en 95.7% de los casos.
- **snippets** presente en 95.7% de los casos.
- **checklists** presente en 76.6% de los casos.
- **errors** presente en 76.6% de los casos.
- **prompts** presente en 61.7% de los casos.

## Alcance y supuestos

Este informe sintetiza patrones y mejores prácticas extraídas de conversaciones de la categoría mencionada.
Se asume que los ejemplos y pasos identificados son representativos del conjunto analizado, pero podrían no cubrir todos los contextos posibles.

## Procedimiento paso a paso

Los siguientes pasos se repiten con frecuencia en las conversaciones:
1. {stem}.ps1 — Contenido EXACTO (sin normalizar).
2. {stem}.md — Markdown con front-matter.
3. {stem}.txt — Texto plano (LF).
4. {stem}.json — Metadatos.
5. {stem}.csv — Metadatos CSV.
6. {stem}.html — Contenido escapado HTML.
7. {stem}_chart.png — Gráfico simple (si hay matplotlib).
8. {stem}_bundle.zip — Paquete ZIP con artefactos.

## Mejores prompts / plantillas

Ejemplos destacados de prompts o plantillas identificados:
- No, quiero que hagas un prompt de mensaje inicial inspirado en la robustez, tono, seriedad y demás de este siguiente:
- Perfecto. Tomando como inspiración el ejemplo que me compartiste, te propongo un **prompt de mensaje inicial** con el mismo tono de seriedad, rigor y robustez, pero orientado a un contexto más **general de orquestación modular reproducible** (alineado con el script `orchestrator_modular.py` que revisamos). Aquí va:
- ¿Quieres que te lo ajuste más hacia un **estilo operativo interno (tipo SOP corporativo como el de Anastasis Revenari)**, o prefieres mantenerlo como un **prompt genérico reutilizable** para cualquier proyecto de orquestación?
- Un prompt generico reutilizable pero que sea estricto.
- Ahora, sumale de forma genérica todo lo que incluye esto en cuanto a impacto, no hagas el prompt de temas binarios, solo hazlo igual de poderoso que la suma del anterior y el siguiente:

## Ejemplos completos

- [grupo-07_prompts-plantillas_ejemplo_7.txt] — sha256: 580756ef4694b097429dc1ef807e238841b420b5b5e4dba8743f4b80f73f44f7 — resumen: # orchestrator_modular.py; # - Un módulo/artefacto por iteración: ps1, txt, md, html, json, csv, png, explanation, bundle; # - Idempotente (compara hash) + escritura atómica (os.replace con archivo te
- [grupo-07_prompts-plantillas_ejemplo_8.txt] — sha256: a7e94710f70f17a05e0e26cb913097edb3909d902361f96e02668f0a705acece — resumen: USER_CONTENT = "Hola Mundo"; run_module("ps1", USER_CONTENT, stem="ejemplo")        # Guarda .ps1; run_module("md", USER_CONTENT, stem="ejemplo")         # Guarda .md; run_module("json", USER_CONTENT,
- [grupo-07_prompts-plantillas_ejemplo_9.txt] — sha256: 205c1908b43888ecc010ee1bcf7bea2cda220879ad825c520cc03c6d1c8c19d0 — resumen: <ROLE>;   Eres GPT-5 especializado en automatización reproducible.;   Trabajas de forma AGENTIC extremo-a-extremo: entregas artefactos completos y un reporte técnico con métricas y verificación, todo 

## Snippets de código / comandos

Algunos fragmentos de código o comandos breves:
```
{ "temperature": 0.2, "top_p": 0.2, "max_tokens": 2048 }
```
```
{ "temperature": 0.2, "top_k": 25, "max_tokens": 2048 }
```
```
{ "temperature": 0.5, "top_p": 0.8, "max_tokens": 2048 }
```
```
{ "temperature": 0.9, "top_p": 0.95, "max_tokens": 2048 }
```
```
for mod, result in run_iterative("Hola mundo", stem="demo"):
    print(f"{mod} -> {result['status']}")
    # Aquí podrías meter análisis, validación, incluso detener el loop si algo falla
```

## Checklists (previo, durante, posterior)

Ejemplos de ítems de checklist encontrados:
- - [ ] Cumple el formato solicitado al 100%.
- - [ ] Terminología y cifras consistentes en todo el texto.
- - [ ] No introduces supuestos sin declararlos.
- - [ ] Respuesta replicable (pasos/comandos si aplica).
- - [ ] Cumples formato y contratos de salida.

## Errores comunes y mitigaciones

Errores o problemas frecuentes mencionados:
- raise RuntimeError(f"No se pudo leer '{path}': {e}") from e
- raise ValueError(f"Módulo desconocido: {module}")
- 3) Transparencia: si un intento falla, registra el error mínimo y continúa con el resto.
- 2) Transparencia: errores se documentan explícitamente sin detener el flujo.
- - Si ocurre error en lectura/escritura, registrar fallo y continuar con el resto de módulos.

## Métricas / criterios de calidad

Cobertura promedio de secciones en las conversaciones: 83.7%.
Total de conversaciones en el grupo: 47.

## Apéndice A: Decisiones de fusión (IDs, umbrales, razones)

No se registraron duplicados ni fusiones en este grupo.

## Apéndice B: Mapa de trazabilidad del grupo (tabla)

| id_fuente | titulo | roles_presentes | cobertura % | duplicado | neardup | jaccard | canonico |
|---|---|---|---|---|---|---|---|
| 1-23-22-Explicaci_n_script_orquestador | Explicación script orquestador | assistant|system|tool|user | 100% | no | no |  |  |
| 1-47-33-An_lisis_de_prompt_t_cnico | Análisis de prompt técnico | assistant|system|tool|user | 100% | no | no |  |  |
| 2-8-10-Reporte_de_fallas | Reporte de fallas | assistant|system|tool|user | 100% | no | no |  |  |
| 3-57-48-_An_lisis___Integraci_n_ | &lt;Análisis - Integración&gt; | assistant|system|tool|user | 100% | no | no |  |  |
| 4-58-47-_WsW_mnt_ | &lt;WsW_mnt&gt; | assistant|system|tool|user | 50% | no | no |  |  |
| 5-16-29-_WsW_Script_ | &lt;WsW_Script&gt; | assistant|system|user | 83% | no | no |  |  |
| 5-22-31-_WsW_Contexto_ | &lt;WsW_Contexto&gt; | assistant|system|user | 50% | no | no |  |  |
| 5-30-5-_PS_Master_XML_Config_ | &lt;PS_Master XML Config&gt; | assistant|system|user | 83% | no | no |  |  |
| 5-36-5-_SOP_01___An_lisis__01_ | &lt;SOP_01 - Análisis #01&gt; | assistant|system|user | 83% | no | no |  |  |
| 5-40-13-_SOP_Backticks_Fences_Here_Strings_ | &lt;SOP_Backticks_Fences_Here-Strings&gt; | assistant|system|user | 83% | no | no |  |  |
| 5-48-30-_SOP_01___An_lisis__03_ | &lt;SOP_01 - Análisis #03&gt; | assistant|system|tool|user | 83% | no | no |  |  |
| 5-50-50-_SOP___Env_Survey_ | &lt;SOP - Env Survey&gt; | assistant|system|user | 100% | no | no |  |  |
| 5-52-44-_SOP_01___An_lisis__03_ | &lt;SOP_01 - Análisis #03&gt; | assistant|system|user | 100% | no | no |  |  |
| 5-56-17-_An_lisis_Config_ | &lt;Análisis Config&gt; | assistant|system|user | 67% | no | no |  |  |
| 5-58-16-_Trazabilidad_y_coherencia_ | &lt;Trazabilidad y coherencia&gt; | assistant|system|user | 100% | no | no |  |  |
| 6-0-1-_Config_YSD_ | &lt;Config YSD&gt; | assistant|system|user | 83% | no | no |  |  |
| 6-11-18-An_lisis_de_documentaci_n_PS | Análisis de documentación PS | assistant|system|user | 100% | no | no |  |  |
| 6-14-34-An_lisis_de_script_PowerShell | Análisis de script PowerShell | assistant|system|user | 67% | no | no |  |  |
| 6-19-13-An_lisis_PUAV_Compat | Análisis PUAV-Compat | assistant|system|user | 100% | no | no |  |  |
| 6-20-18-An_lisis_SOP_01_y_errores | Análisis SOP-01 y errores | assistant|system|user | 83% | no | no |  |  |
| 6-22-21-Lee_y_analiza_script | Lee y analiza script | assistant|system|user | 83% | no | no |  |  |
| 6-23-21-New_chat | New chat | assistant|system|tool|user | 83% | no | no |  |  |
| 6-26-32-An_lisis_de_instrucciones_proyecto | Análisis de instrucciones proyecto | assistant|system|user | 83% | no | no |  |  |
| 6-29-54-An_lisis_de_instrucciones | Análisis de instrucciones | assistant|system|user | 83% | no | no |  |  |
| 6-31-26-Auditor_a_de_configuraci_n | Auditoría de configuración | assistant|system|user | 100% | no | no |  |  |
| 6-34-30-An_lisis_protocolo_auditor_a | Análisis protocolo auditoría | assistant|system|user | 83% | no | no |  |  |
| 6-36-14-An_lisis_y_auditor_a_t_cnica | Análisis y auditoría técnica | assistant|system|user | 100% | no | no |  |  |
| 6-40-30-An_lisis_SOP_auditor_a | Análisis SOP auditoría | assistant|system|user | 100% | no | no |  |  |
| 6-45-32-An_lisis_README_proyecto | Análisis README proyecto | assistant|system|user | 67% | no | no |  |  |
| 6-50-15-An_lisis_de_protocolo_SOP01 | Análisis de protocolo SOP01 | assistant|system|tool|user | 100% | no | no |  |  |
| 6-7-43-An_lisis_SOP_01 | Análisis SOP-01 | assistant|system|user | 83% | no | no |  |  |
| 6-9-11-Instrucciones_de_ejecuci_n | Instrucciones de ejecución | assistant|system|user | 83% | no | no |  |  |
| 12-21-35-Ejemplo_prompt_Codex_Powershell | Ejemplo prompt Codex Powershell | assistant|system|tool|user | 67% | no | no |  |  |
| 12-34-51-Prompt_para_PowerShell_Codex | Prompt para PowerShell Codex | assistant|user | 83% | no | no |  |  |
| 20-31-17-Resumen_autom_tico_correos | Resumen automático correos | assistant|system|tool|user | 67% | no | no |  |  |
| 7-7-32-Significado_de_un_script | Significado de un script | assistant|system|user | 83% | no | no |  |  |
| 13-0-2-Revisi_n_de_memoria_persistente | Revisión de memoria persistente | assistant|user | 100% | no | no |  |  |
| 13-9-57-Cargar_informaci_n_contextual | Cargar información contextual | assistant|user | 100% | no | no |  |  |
| 2-57-37-Normativa_operativa_guardada | Normativa operativa guardada | assistant|system|tool|user | 83% | no | no |  |  |
| 3-32-16-Generar_script_HTML_desde__md | Generar script HTML desde .md | assistant|user | 100% | no | no |  |  |
| 6-43-13-Interpretaci_n_de_documento | Interpretación de documento | assistant|system|tool|user | 100% | no | no |  |  |
| 7-25-19-Entendimiento_de_documento_JSON | Entendimiento de documento JSON | assistant|system|tool|user | 83% | no | no |  |  |
| 2-27-5-Plan_de_limpieza_Excel | Plan de limpieza Excel | assistant|user | 83% | no | no |  |  |
| 0-32-13-Crear_imagen_estilo_caricatura | Crear imagen estilo caricatura | assistant|user | 83% | no | no |  |  |
| 1-58-21-Ilustraci_n_de_perro | Ilustración de perro | assistant|user | 17% | no | no |  |  |
| 1-58-38-Ilustraci_n_art_stica_perro | Ilustración artística perro | assistant|user | 17% | no | no |  |  |
| 8-52-38-Significado_de_Anastasis_Revenari | Significado de Anastasis Revenari | assistant|system|user | 100% | no | no |  |  |