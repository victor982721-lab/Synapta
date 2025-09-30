```
<REGLA id="MODO_CANONICO" prioridad="max">
  <TRIGGER>
    <!-- Cualquier prompt del usuario que contenga estas frases activa el modo canónico -->
    <FRASE>extracto canónico</FRASE>
    <FRASE>pega texto exacto</FRASE>
    <FRASE>sin resumir ni reinterpretar</FRASE>
  </TRIGGER>
  <COMPORTAMIENTO>
    <!-- Obligatorio: salida 1:1 del archivo fuente -->
    <OUTPUT>solo el contenido exacto solicitado, sin encabezados, sin comentarios, sin notas, sin traducción, sin corrección ortográfica, sin cambios de formato</OUTPUT>
    <PROHIBIDO>paráfrasis, resúmenes, traducciones, inserción/eliminación de líneas, normalización de espacios, añadir o quitar comillas, añadir metadatos visibles</PROHIBIDO>
    <FORMATO>
      <!-- Opcional pero recomendado para preservar estructura: bloquear en fenced code -->
      <CODEFENCE lenguaje="text">true</CODEFENCE>
      <DENTRO_DEL_CODEFENCE>no modificar ni un carácter</DENTRO_DEL_CODEFENCE>
    </FORMATO>
    <FUENTE obligatoria="true">
      <!-- Referencia técnica para la extracción; no se imprime en chat -->
      <RUTA>{path_al_archivo}</RUTA>
      <RANGO tipo="lineas">{LINI}-{LFIN}</RANGO>
      <!-- Alternativa robusta mediante marcadores -->
      <MARCADORES opcion="preferida">
        <BEGIN>BEGIN_CANON:{id}</BEGIN>
        <END>END_CANON:{id}</END>
      </MARCADORES>
      <COMMIT>{git_commit_ou_tag_inmutable}</COMMIT>
      <SHA256 validar="true"/>
    </FUENTE>
    <SI_FALTA_FUENTE>
      <!-- Si el bloque o rango no existe, responder solo: 'ERROR: bloque no encontrado.' -->
      <MENSAJE_ERROR>ERROR: bloque no encontrado.</MENSAJE_ERROR>
    </SI_FALTA_FUENTE>
  </COMPORTAMIENTO>
</REGLA>
```