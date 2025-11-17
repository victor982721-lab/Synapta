using System.Threading;            // CancellationToken, ManualResetEventSlim
using System.Threading.Tasks;     // Task, async/await

namespace Ws_Insights.Utilities;

// -----------------------------------------------------------------------------
// PauseTokenSource
// -----------------------------------------------------------------------------
// Esta clase implementa un sistema de PAUSA/REANUDACIÓN cooperativa, similar a
// CancellationTokenSource, pero sin cancelar el trabajo.  
// Su función: permitir que cualquier operación async se detenga temporalmente
// llamando a await token.WaitIfPausedAsync(ct).
// -----------------------------------------------------------------------------

public sealed class PauseTokenSource : IDisposable
{
    // ManualResetEventSlim es una especie de semáforo muy rápido.
    // true = está "abierto" → las tareas NO se bloquean.
    // false = está "cerrado" → las tareas que llamen Wait() quedan detenidas.
    private readonly ManualResetEventSlim _mre = new(true);

    // Indica si el estado actual es "en pausa".
    public bool IsPaused { get; private set; }

    // Token expuesto para las tareas (símil CancellationToken → PauseToken).
    public PauseToken Token => new(this);

    // -------------------------------------------------------------------------
    // PAUSE
    // -------------------------------------------------------------------------
    // Cambia el estado a "pausado" y bloquea el _mre para que las tareas
    // queden detenidas cuando llamen WaitIfPausedAsync().
    // -------------------------------------------------------------------------
    public void Pause()
    {
        if (IsPaused) return;  // Ya está pausado
        IsPaused = true;
        _mre.Reset();          // Bloquea → las tareas comenzarán a esperar
    }

    // -------------------------------------------------------------------------
    // RESUME
    // -------------------------------------------------------------------------
    // Cambia el estado a "activo" y libera el _mre, permitiendo que todas las
    // tareas detenidas continúen inmediatamente.
    // -------------------------------------------------------------------------

    public void Resume()
    {
        if (!IsPaused) return;  // Ya estaba activo
        IsPaused = false;
        _mre.Set();             // Libera → las tareas bloqueadas continúan
    }

    // -------------------------------------------------------------------------
    // WaitWhilePausedAsync
    // -------------------------------------------------------------------------
    // Método interno que las tareas llaman para cooperar con la pausa.
    // Si NO está pausado, devuelve una tarea completada inmediatamente.
    // Si está pausado, crea una tarea que se bloqueará en _mre.Wait().
    // Esto NO congela el UI thread, porque la espera ocurre en un Task.Run().
    // -------------------------------------------------------------------------

    internal Task WaitWhilePausedAsync(CancellationToken cancellationToken)
    {
        if (!IsPaused)
            return Task.CompletedTask;  // No hacer nada si no está en pausa

        // Crea una tarea que espera a que _mre.Set() sea llamado,
        // o que el CancellationToken se dispare.
        return Task.Run(() => _mre.Wait(cancellationToken), cancellationToken);
    }

    // Limpieza del semáforo interno
    public void Dispose()
    {
        _mre.Dispose();
    }
}

// -----------------------------------------------------------------------------
// PauseToken
// -----------------------------------------------------------------------------
// Versión liviana del token.  
// Funciona igual que CancellationToken → un struct pasivo que llama al source.
// -----------------------------------------------------------------------------

public readonly struct PauseToken
{
    private readonly PauseTokenSource? _source;

    // Token vacío (no hace nada).
    public static PauseToken None { get; } = new(null);

    internal PauseToken(PauseTokenSource? source)
    {
        _source = source;
    }

    // -------------------------------------------------------------------------
    // WaitIfPausedAsync
    // -------------------------------------------------------------------------
    // Las tareas llaman esto para detenerse si el sistema está en pausa.
    //
    // Caso 1: No hay source → devuelve CompletedTask.
    // Caso 2: No está pausado → CompletedTask.
    // Caso 3: Está pausado → espera hasta que Resume() sea llamado.
    // -------------------------------------------------------------------------
    
    public Task WaitIfPausedAsync(CancellationToken cancellationToken)
    {
        return _source?.WaitWhilePausedAsync(cancellationToken)
               ?? Task.CompletedTask;  // Si el source es null, no hace nada.
    }
}
