# README - Ws_Insights

Ws_Insights es una aplicación de búsqueda de escritorio construida con WPF y .NET.  Su objetivo es ofrecer indexado y búsqueda de archivos de forma rápida, con una arquitectura moderna y mantenible.  Esta versión parte **desde cero** con un repositorio ordenado y preparado para soportar múltiples versiones de .NET, garantizando un punto de partida limpio para el desarrollo de la interfaz y del motor.

## Compilación y compatibilidad de .NET

El proyecto está orientado a **.NET 8**, pero gracias a la propiedad `TargetFrameworks` también es plenamente compatible con **.NET 7** y **.NET 6**.  Esto significa que la misma base de código se puede compilar y ejecutar en entornos con diferentes versiones del framework sin modificaciones.  Para lograrlo, el archivo `Ws_Insights.csproj` incluye la siguiente definición:

```xml
<TargetFrameworks>net8.0-windows;net7.0-windows;net6.0-windows</TargetFrameworks>
```

El parámetro `UseWPF` está habilitado para todos los destinos, de modo que las mismas vistas XAML funcionan en cada versión.  Cuando Codex genere nuevos proyectos, deberá mantener esta triple compatibilidad.

### Requisitos y comandos básicos

- **Herramientas y SDK:** Visual Studio 2022 o posterior con soporte para WPF, junto con los SDK de .NET 8/7/6 instalados.  
- **Restaurar paquetes:** `dotnet restore`  
- **Compilar:** `dotnet build`  
- **Ejecutar:** `dotnet run --framework net8.0-windows` (sustituye `net7.0-windows` o `net6.0-windows` según tu runtime predeterminado).  

Asegúrate de que tu entorno tenga habilitado el soporte para aplicaciones WPF.

## Estructura del repositorio

Todo el código fuente y los artefactos se encuentran dentro de `Neurologic/Sandbox/Ws_Insights/`.  La estructura de carpetas está pensada para que cada directorio represente un *namespace* y una responsabilidad clara.  La versión completa del árbol se encuentra en `docs/filemap_ascii.txt` y en las tablas CSV en `csv/`.  Un resumen de alto nivel:

- **Scripts/** contiene instaladores y scripts de utilidades.  
- **Models/** define los registros y objetos de datos utilizados por la interfaz.  
- **File_Extensions/** implementa la UI para configurar extensiones y categorías.  
- **Reporting/** incluye exportadores como `Csv.Exporter.cs`.  
- **Utilities/** expone utilidades transversales (pausa, registro de sesiones, extractor de rangos de texto).  
- **Search.Engine/** implementa el motor de búsqueda: cachés, entrada/salida, indexación y procesamiento.  Es un componente sin UI.  
- **Search/** provee la fachada de alto nivel para la UI (contexto, opciones, resultados) y orquesta llamadas al motor.  
- **App.xaml** y **MainWindow.xaml** alojan la definición de la aplicación y la ventana principal de WPF.  
- **ThemeDark.xaml** y **ThemeLight.xaml** contienen los recursos de tema para estilos oscuros y claros.  

## Principios de diseño y estética

- **Patrón MVVM**: la interfaz se basa en el patrón *Model–View–ViewModel* para desacoplar la lógica de presentación de las vistas.  
- **Estética minimalista**: se emplea un diseño moderno y limpio.  Los colores y pinceles se definen en los diccionarios de temas.  
- **Responsividad**: las vistas usan `Grid`, `DockPanel` y controles adaptativos para funcionar en diferentes tamaños de ventana.  
- **Consistencia**: la jerarquía de carpetas y namespaces es determinista; cada carpeta corresponde a un namespace.  Los cambios en esta estructura deben hacerse con cuidado y deben reflejarse en los CSV y en `AGENTS.md`.

## Recursos adicionales
 
- Los ficheros CSV bajo `csv/` ofrecen un inventario detallado de cada archivo y su estado.  
- El archivo JSON `docs/table_hierarchy.json` mapea cada carpeta con su CSV correspondiente.