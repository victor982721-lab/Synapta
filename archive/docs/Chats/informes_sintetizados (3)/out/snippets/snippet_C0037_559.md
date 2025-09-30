```xml
<PROCEDIMIENTO id="LECTURA_CANONICA">
  <PASO>Resolver ruta y commit/tag inmutable del archivo fuente.</PASO>
  <PASO>Preferir extracción por marcadores BEGIN_CANON/END_CANON; si no existen, usar rango de líneas exacto.</PASO>
  <PASO>Calcular SHA256 del archivo y registrar en bitácora (no mostrar en chat).</PASO>
  <PASO>Activar TRIGGER del MODO_CANONICO y devolver SOLO el bloque literal dentro de code fence.</PASO>
</PROCEDIMIENTO>
```