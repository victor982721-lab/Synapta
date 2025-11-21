# Reestructura_Codex

Auditoría y empaquetado del repositorio propuesto en `Repo/`, asegurando que la estructura, documentación y artefactos resultantes sean fáciles de consumir por agentes (Codex/ChatGPT) y repetibles para nuevas solicitudes de código.

## Cómo usar este paquete
- Lee `docs/solicitud_de_artefactos.md` para entender cómo redactar pedidos a Codex con el inventario actual.
- Revisa `docs/filemap_ascii.txt` y `docs/table_hierarchy.json` para ubicar artefactos y dependencias sin recorrer manualmente el árbol.
- Consulta `csv/modules.csv` y `csv/artefacts.csv` para ver el inventario declarativo (componentes, estado y responsables) antes de pedir cambios.
- Usa el árbol `Repo/` como fuente única de verdad: `Core/` contiene librerías reutilizables, `Sandbox/` alberga ejemplos y `Scripts/` ofrece utilidades globales.

## Flujo recomendado
1. Releer `AGENTS.md` (global y específicos) y la `Política cultural` antes de solicitar o generar cambios.
2. Actualizar los CSV y mapas si se agregan artefactos nuevos o cambia la arquitectura.
3. Para código ejecutable, planear validaciones (`dotnet test`, PSSA) según indiquen los AGENTS; para documentación o plantillas, basta con mantener los inventarios sincronizados.
