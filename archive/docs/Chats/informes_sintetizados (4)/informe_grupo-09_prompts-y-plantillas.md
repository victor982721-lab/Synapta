# Prompts y plantillas

## Resumen ejecutivo

Este informe sintetiza 6 conversación(es) consolidadas del tema **Prompts y plantillas**.

## Alcance y supuestos

- Basado exclusivamente en el contenido presente en las conversaciones fuente.
- Se excluyen saludos, disculpas y texto genérico sin valor técnico.
- Se preservan fragmentos técnicos, prompts y código tal como aparecen (con mínimos ajustes de formato).

## Procedimiento paso a paso

1. **Inicio general, luego especificar**: Se comienza con una descripción amplia del objetivo (automatizar la creación de un informe en CSV) y luego se detallan los requisitos específicos.
2. **Proporcionar ejemplos**: Se incluye un ejemplo de la salida esperada para guiar a Copilot en la generación del código.
3. **Descomponer tareas complejas**: Se especifican pasos individuales como obtener servicios, filtrarlos, exportar a CSV y manejar errores.
4. **Evitar ambigüedades**: Se utilizan términos claros y se especifica el entorno de ejecución (PowerShell 7.3 en Windows 10 Pro 22H2).
5. **Experimentar e iterar**: Si la salida generada no cumple con las expectativas, se ajusta el prompt para refinar los resultados.
6. **Mantener historial relevante**: En sesiones de Copilot Chat, se conserva el contexto pertinente para tareas continuas.
7. **Seguir buenas prácticas de codificación**: Se especifica el uso de `Write-Output` o `Write-Error` en lugar de `Write-Host` y se enfatiza la compatibilidad con versiones específicas de PowerShell.
1. Segunda pasada con el **mismo prompt** y *strength* **0.20–0.30** para “retintar” líneas y micro‑detalle.
2. Añade **textura de papel** sutil (overlay/multiply 10–15%) y un toque de **film grain** fino para cohesión.
1) Cambia el modelo a **GPT‑5**.
2) Adjunta una de tus fotos y pega el prompt del `.md`.
3) Genera **4–6 variaciones** a 2048–4096 px, elige la mejor y **upscale** 2×–4×.
4) (Opcional) Segunda pasada con *strength* 0.20–0.30 para refinar líneas + textura de papel (overlay 10–15%) y grano suave.

## Mejores prompts / plantillas

- Prompt para PowerShell Codex
- 🎯 Prompt para GitHub Copilot en PowerShell
- Prompt listo para pegar (imagen‑a‑imagen, adjunta la foto)

## Ejemplos completos

- [ej_prompts_plantillas_12-34-51-Prompt_para_PowerShell_Codex.md] — sha256: 62d523511b9e931ea11cb76b6ecb616113da0b537f00df9e0fe8def96a5ebc7f — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\nRole: Soy un profesional con amplia experiencia en automatización y administración de sistemas utilizando PowerShell. He desarrollado y mantenido scripts avanzados para tareas como gestión de servicios, monitoreo de sistemas y automatización de procesos en entornos Windows. Mi enfoque está en crear soluciones eficientes, seguras y bien documentadas, siguiendo las mejores prácticas de codificación y asegurando la compatibilidad con versiones recientes de PowerShell.\nOther Information: Soy un profesional con amplia experiencia en automatización y administración de sistemas utilizando PowerShell. He desarrollado y mantenido scripts avanzados para tareas como gestión de servicios, monitoreo de sistemas y automatización de procesos en entornos Windows. Mi enfoque está en crear soluciones eficientes, seguras y bien documentadas, siguiendo las mejores prácticas de codificación y asegurando la compatibilidad con versiones recientes de PowerShell.\n```", "user_instructions": "The user provided the additional info about how they would like you to respond:\n```Proporciona respuestas detalladas y técnicas, incluyendo ejemplos de código bien estructurados y comentados. Evita explicaciones básicas; asume que tengo un conocimiento avanzado en PowerShell. Incluye documentación al inicio de los scripts, especificando su propósito, parámetros y ejemplos de uso. Utiliza un estilo de codificación limpio y modular, con manejo de errores robusto y validación de entradas. Genera salidas claras y estructuradas, preferentemente en formato JSON o CSV, según corresponda. Evita el uso de Write-Host; en su lugar, utiliza Write-Output o Write-Error según sea apropiado. Asegura la compatibilidad con PowerShell 7.3 en sistemas Windows 10 Pro versión 22H2.```"}

  ### Salida (assistant)

- [ej_prompts_plantillas_0-32-13-Crear_imagen_estilo_caricatura.md] — sha256: ca635ad19ef1d72d5aa6b29586d08fe33670f0b7cf7ceaebd90a7b84de035ce9 — resumen

  ### Entrada (user)

  {'content_type': 'image_asset_pointer', 'asset_pointer': 'file-service://file-BozL6PXmMyAb7MLMjnByvb', 'size_bytes': 291304, 'width': 3060, 'height': 4080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None}}
  ChatGPT crea una imagen a partir de esta fotografía, creala con el estilo de Heidi o de Candy Candy, una de esas caricaturas, con la misma tonalidad, mismo estilo de dibujo, mismos colores, mismo todo, y a ver cómo queda.


- [ej_prompts_plantillas_1-56-43-Convierte_foto_en_ilustraci_n.md] — sha256: 1277d4f2582fbc330a4ffdfdcc1217d494ffdaa6a9ca7a97f8d31065d30a911d — resumen

  ### Entrada (user)

  {'content_type': 'image_asset_pointer', 'asset_pointer': 'file-service://file-56gfTZ9fYqkKkBy3qqAu6A', 'size_bytes': 291304, 'width': 3060, 'height': 4080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None}}
  Convierte esta foto en una ilustración de alta calidad, no fotorrealista.
  Un perro mayor negro con marcas canela, hocico canoso y ojos ámbar, tumbado

- [ej_prompts_plantillas_1-57-52-Ilustraci_n_de_perro_art_stico.md] — sha256: 608090c080d3596aa8bbb9f5dde743f11e4ce8bd0a5643d2bd82d67847172ad7 — resumen

  ### Entrada (user)

  Convierte esta foto en una ilustración de alta calidad, no fotorrealista.
  Un perro mayor negro con marcas canela, hocico canoso y ojos ámbar, tumbado
  con las patas delanteras extendidas sobre baldosas crema con azul. Mantén su

- [ej_prompts_plantillas_1-58-21-Ilustraci_n_de_perro.md] — sha256: 675a1253f39ad0172c9bcf515806be64a924edff5f1ab69f79bab4c0ed0048eb — resumen

  ### Entrada (user)

  Convierte esta foto en una ilustración de alta calidad, no fotorrealista.
  Un perro mayor negro con marcas canela, hocico canoso y ojos ámbar, tumbado
  con las patas delanteras extendidas sobre baldosas crema con azul. Mantén su

- [ej_prompts_plantillas_1-58-38-Ilustraci_n_art_stica_perro.md] — sha256: 675a1253f39ad0172c9bcf515806be64a924edff5f1ab69f79bab4c0ed0048eb — resumen

  ### Entrada (user)

  Convierte esta foto en una ilustración de alta calidad, no fotorrealista.
  Un perro mayor negro con marcas canela, hocico canoso y ojos ámbar, tumbado
  con las patas delanteras extendidas sobre baldosas crema con azul. Mantén su

## Snippets de código / comandos

- [sn_prompts_plantillas_12-34-51-Prompt_para_PowerShell_Codex_001.ps1] — sha256: 39a4d484d8eccf498d103ea47c254757151a59a8921c0f1b28a6383476d9fe0f — resumen

  # Generar un script en PowerShell que automatice la creación de un informe en formato CSV
  # con el estado de los servicios de Windows, incluyendo:
  # - Nombre del servicio
  # - Estado (en ejecución, detenido, etc.)
  # - Descripción

- [sn_prompts_plantillas_0-32-13-Crear_imagen_estilo_caricatura_002.txt] — sha256: 726ef78d9768a1f0ef31c9acdf5dd777c278491f66bca1db6af71d912d6bcb2b — resumen

  Convierte esta foto en una ilustración de alta calidad, no fotorrealista.
  Un perro mayor negro con marcas canela, hocico canoso y ojos ámbar, tumbado
  con las patas delanteras extendidas sobre baldosas crema con azul. Mantén su
  identidad y mirada cálida (una oreja algo más erguida), pero hazlo obra de arte:
  mezcla de caricatura clásica + ilustración editorial + cómic europeo + shōjo setentero,

- [sn_prompts_plantillas_0-32-13-Crear_imagen_estilo_caricatura_003.txt] — sha256: c2a8b9d0124f24a42627b6aa7553d446ffde486486018e30caed38240697c9da — resumen

  hiperrealismo, plástico/CGI, ojos desalineados, anatomía extraña, duplicados,
  artefactos, texto o marcas de agua, glitches, fondos vacíos, copia de un estilo único
  (Heidi/Candy), low‑res, oversharpen

## Checklists (previo, durante, posterior)

- ⚠️ FALTA: Checklist explícita (sin evidencia)

## Errores comunes y mitigaciones

- ⚠️ FALTA: Errores/mitigaciones (sin evidencia)

## Métricas / criterios de calidad

- ⚠️ FALTA: Métricas/criterios (sin evidencia)

## Apéndice A: Decisiones de fusión (IDs, umbrales, razones)

- Sin decisiones de fusión registradas para este grupo.

## Apéndice B: Mapa de trazabilidad del grupo (tabla)

| archivo_original | sha256 | título/tema detectado | rol(es) relevantes | porción aprovechada |
|---|---|---|---|---|
| 2025-9-15/12-34-51-Prompt_para_PowerShell_Codex.md | 857d0f8283dc1fb3eaa962f16267a68c69b584c8564e6123b13d7cb206faf4f8 | Prompt para PowerShell Codex | assistant, system, tool, user | sí |
| 2025-9-24/0-32-13-Crear_imagen_estilo_caricatura.md | 29fa92a56c5a9a724c07d55de131f50ce4a08699fed651d62a280727e45b04bf | Crear imagen estilo caricatura | assistant, system, tool, user | sí |
| 2025-9-24/1-56-43-Convierte_foto_en_ilustraci_n.md | f15e97aad4a58820abb359f88154a2733898e65815246bddfb015be7f119162c | Convierte foto en ilustración | assistant, system, tool, user | sí |
| 2025-9-24/1-57-52-Ilustraci_n_de_perro_art_stico.md | c0d5d8c639d2d82a739dd1c8c391dfb3567fae1a7e8f806dee302e47c6b45d87 | Ilustración de perro artístico | assistant, system, tool, user | sí |
| 2025-9-24/1-58-21-Ilustraci_n_de_perro.md | 7124e5cf9d36219713a355da03e2d50b466cd212449e1c9c2f0e7814813f9ba9 | Ilustración de perro | assistant, system, tool, user | sí |
| 2025-9-24/1-58-38-Ilustraci_n_art_stica_perro.md | 12d2502692b406e2bf351173250cb8d8d2cd4b8faab5fdf489dc4da717eb0a70 | Ilustración artística perro | assistant, system, tool, user | sí |
