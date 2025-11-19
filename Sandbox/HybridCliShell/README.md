# Shell híbrido CLI + WPF

Este módulo provee una base reutilizable para aplicaciones WPF modernas que necesitan convivir con comandos CLI. Se ejecuta sobre .NET 6, 7 y 8 e incluye:

- **Host genérico** basado en `Microsoft.Extensions.Hosting` para compartir servicios entre la UI y la línea de comandos.
- **Parser CLI** construido con `System.CommandLine` (`--cli status`, `--cli pulse`, `--cli --theme dark`, etc.).
- **Diccionarios de recursos** para tema claro/oscuro y un set predefinido de estilos.
- **Stream de telemetría** (async + `Channel<T>`) que alimenta tanto al CLI como a la UI.
- **ViewModel** (CommunityToolkit.Mvvm) que expone comandos reutilizables y colecciones observables.

## Ejecución

```powershell
# UI tradicional
dotnet run --project HybridCliShell

# Solo CLI (sin abrir la ventana)
dotnet run --project HybridCliShell -- --cli status
```

## Extensión

1. Registra tus servicios en `HybridBootstrapper`.
2. Agrega comandos nuevos dentro de `HybridCommandHost` para compartir lógica con scripts.
3. Crea estilos adicionales dentro de `Themes/*.xaml` y aplica bindings en `ShellWindow`.

El objetivo es que esta pieza funcione como plantilla para futuros scripts con UI + CLI unificada.
