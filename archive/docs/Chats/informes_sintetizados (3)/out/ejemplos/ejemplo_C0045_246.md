```xml
<?xml version="1.0" encoding="UTF-8"?>
<auditoriaProtocolo xmlns="urn:anastasis-revenari:auditoria:1.0">
  <metadata>
    <nombre>Auditoría de Configuración de Proyecto — Protocolo General</nombre>
    <version>1.0</version>
    <proposito>Evaluar si un proyecto de ChatGPT aprovecha correctamente Custom Instructions, Project Instructions, archivos y (si aplica) Memoria — independientemente del dominio.</proposito>
  </metadata>

  <entradasRequeridas>
    <entrada id="project-instructions" tipo="texto">Texto actual en Project Instructions.</entrada>
    <entrada id="custom-instructions" tipo="texto" subcampos="3">Texto actual en Custom Instructions (los 3 campos).</entrada>
    <entrada id="memoria" tipo="estado">Capturas/confirmaciones de estado de Memoria (OFF o project-only).</entrada>
    <entrada id="archivos" tipo="lista">Listado de archivos del proyecto y su propósito.</entrada>
  </entradasRequeridas>

  <salidasEsperadas>
    <salida id="puntaje">Puntaje (0–100) por dimensiones.</salida>
    <salida id="hallazgos">Hallazgos priorizados (Crítico/Alto/Medio/Bajo).</salida>
    <salida id="acciones">Acciones correctivas concretas (una línea cada una).</salida>
  </salidasEsperadas>

  <dimensiones total="100">
    <dimension id="1" nombre="Claridad y enfoque" peso="20">
      <criterios>Objetivos definidos, tono consistente, cero ambigüedad.</criterios>
    </dimension>
    <dimension id="2" nombre="Proactividad y contrato de entrega" peso="20">
      <criterios>“Un turno, valor”; sin promesas; verificación propia.</criterios>
    </dimension>
    <dimension id="3" nombre="Trazabilidad" peso="15">
      <criterios>Citas a fuentes [Oficial] para capacidades; foros como [Comunidad/Prensa].</criterios>
    </dimension>
    <dimension id="4" nombre="Arquitectura de contexto" peso="15">
      <criterios>Jerarquía correcta (Proyecto &gt; CI &gt; Prompt), sin depender de memoria.</criterios>
    </dimension>
    <dimension id="5" nombre="Operativa de archivos" peso="10">
      <criterios>Nombres ASCII, empaquetado, instrucciones de uso.</criterios>
    </dimension>
    <dimension id="6" nombre="Actualización y UI" peso="10">
      <criterios>Comprobaciones de estado (Proyecto/Memoria), límites de campos medidos.</criterios>
    </dimension>
    <dimension id="7" nombre="Calidad de entregables" peso="10">
      <criterios>Ejemplos reproducibles, validaciones internas.</criterios>
    </dimension>
  </dimensiones>

  <limitesCampos>
    <campo nombre="CustomInstructions" presupuestoCaracteresAprox="1500"/>
    <campo nombre="ProjectInstructions" presupuestoCaracteresAprox="8000"/>
  </limitesCampos>

  <procedimiento>
    <paso numero="1" nombre="Inventario">Extrae texto de CI (3 campos) y Project Instructions; lista archivos y tamaños.</paso>
    <paso numero="2" nombre="Límites">Verifica que cada campo respete su presupuesto (CI ~1500 c/u; Proyecto ~8000 aprox.).</paso>
    <paso numero="3" nombre="Consistencia">Detecta contradicciones entre CI y Proyecto; Proyecto debe prevalecer.</paso>
    <paso numero="4" nombre="Proactividad">Busca frases de prometer más tarde o preguntas innecesarias; deben estar prohibidas.</paso>
    <paso numero="5" nombre="Citas">Comprueba presencia de citas [Oficial] cuando se hable de capacidades o planes.</paso>
    <paso numero="6" nombre="Entregables">Verifica que se pidan nombres ASCII, .zip cuando aplique y guía de validación.</paso>
    <paso numero="7" nombre="Reporte">Emite puntaje por dimensión y lista de acciones (máx. 10 ítems).</paso>
  </procedimiento>

  <politicasEntregables>
    <politica id="nombres-ascii">Requerir nombres ASCII.</politica>
    <politica id="paquete-zip">Usar empaquetado .zip cuando aplique.</politica>
    <politica id="guia-validacion">Incluir guía de validación.</politica>
  </politicasEntregables>

  <severidades>
    <nivel>Crítico</nivel>
    <nivel>Alto</nivel>
    <nivel>Medio</nivel>
    <nivel>Bajo</nivel>
  </severidades>

  <plantillaReporte>
    <ejemplo><![CDATA[
Resumen (score total: 84/100)
- Críticos: 0 | Altos: 1 | Medios: 3 | Bajos: 2
Hallazgos → Acción (una línea):
- Alto — Proyecto excede 8000 char: Reducir y mover detalle a archivos.
- Medio — CI carece de “un turno, valor”: Añadir contrato de entrega.
- Bajo — Falta política de .zip: Incluir en sección de entregables.
    ]]></ejemplo>
  </plantillaReporte>

  <promptOperativo><![CDATA[
Audita este proyecto con el protocolo general. Reporta puntuación por dimensión, hallazgos priorizados y acciones de una línea. Verifica límites (1500/8000 aprox.), consistencia Proyecto↔CI, y políticas de entregables. No hagas preguntas; entrega el informe en un turno.
  ]]></promptOperativo>
</auditoriaProtocolo>
```