```
<OBJETIVOS>
   <OBJETIVO_GENERAL>
      <DESCRIPCION>
         - Establecer y operar un protocolo estandarizado de arranque de sesiones
         - 
         (Prompt Maestro + Auditoría Integral) que parta de un checkpoint controlado 
         y deje trazabilidad end-to-end (CSV inicial y bitácoras) para aumentar 
         consistencia, reproducibilidad, seguridad y mejora continua de los resultados.
      </DESCRIPCION>
      <METRICAS>
         <METRICA nombre="Consistencia">
            Reducir la varianza inter-sesión de salidas en el set base (CSV) a ≤15%.
         </METRICA>
         <METRICA nombre="Reproducibilidad">
            Lograr ≥95% de re-ejecuciones equivalentes en casos deterministas 
            (mismos insumos/parámetros).
         </METRICA>
         <METRICA nombre="Velocidad de arranque">
            Estandarizar el TTI ≤ 3 min desde “nueva sesión” hasta “listo para producir”.
         </METRICA>
         <METRICA nombre="Gobernanza">
            ≥98% de campos obligatorios completados en la Auditoría Integral 
            (prompts, parámetros, fuentes, riesgos).
         </METRICA>
         <METRICA nombre="Calidad/seguridad">
            0 incidentes por manejo de PII/credenciales; ≤2% de hallazgos críticos por sesión.
         </METRICA>
         <METRICA nombre="Mejora continua">
            Incorporar ≥1 ajuste al Prompt Maestro por cada 10 sesiones 
            basado en la evidencia de bitácoras.
         </METRICA>
      </METRICAS>
   </OBJETIVO_GENERAL>

   <OBJETIVO_PARTICULAR>
      <PROYECTO nombre="AutoScript_AR">
         <PUNTO> Cumplimiento obligatorio de lectura y ejecución de SOP01 cada que se inicia una nueva sesión. (Este documento) </PUNTO>
         <PUNTO> Alineación con las capacidades y cambios de ChatGPT posteriores al cut-off (junio de 2024). </PUNTO>
         <PUNTO> Coherencia entre las instrucciones y los archivos del proyecto. </PUNTO>
      </PROYECTO>
   </OBJETIVO_PARTICULAR>
</OBJETIVOS>
```