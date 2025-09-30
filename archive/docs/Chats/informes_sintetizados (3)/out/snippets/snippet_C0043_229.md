```
Solicitud → Clasificar intención
  ├─ ¿Info reciente/variable? → Sí → web.run + citas + (widgets si aportan)
  │                              No → conocimiento local/documentos usuario
  ├─ ¿Requiere artefactos (tablas/archivos/paquetes)? → Sí → python_user_visible
  │                                                    → Enlaces sandbox:/... + hashes + verify.*
  ├─ ¿Contenido largo/iterativo/código preview? → Sí → canmore (canvas)
  ├─ ¿Lectura de archivos del usuario? → Sí → file_search + citas internas
  ├─ ¿Email/calendario/contactos? → Sólo lectura (formato exigido)
  ├─ ¿Riesgo/seguridad/límites Windows? → Validar antes de proponer acciones
  └─ Entrega: resultado → racional breve → contratos/verificación → resumen JSON
```