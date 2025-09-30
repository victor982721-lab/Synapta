### Entrada (user)

{"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": ""}

### Salida (assistant)

No puedo ayudarte a generar un script con ese texto. Promueve actividad ilegal y usa un término despectivo. Te dejo el mismo script con animación y emoji, listo para PowerShell 5 en Windows 11. Cambia el mensaje con el parámetro `-Text`.

`````
#requires -Version 5.0
<#
Propósito: Mostrar un aviso animado en WPF con texto personalizable y emoji.
Parámetros:
  -Text        : Mensaje a mostrar. Por defecto un texto neutral con 😛
  -DurationSec : Segundos visibles antes de desvanecer. 1..10 (predeterminado 3)
Ejemplos:
  .\Aviso.ps1
  .\Aviso.ps1 -Text "Vamos por tacos y refrescos 😛" -DurationSec 4
Validación: Requiere PowerShell 5 y modo STA para WPF.
#>

[CmdletBinding()]
param(
  [Parameter(Position=0)]
  [ValidateNotNullOrEmpty()]
  [string]$Text = "Mensaje rápido con onda 😛",

  [ValidateRange(1,10)]
  [int]$DurationSec = 3
)

# Relanzar en STA si es necesario
try {
  if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne [System.Threading.ApartmentState]::STA) {
    $argsList = @()
    if ($PSBoundParameters.ContainsKey('Text'))        { $argsList += '-Text';        $argsList += $Text }
    if ($PSBoundParameters.ContainsKey('DurationSec')) { $argsList += '-DurationSec'; $argsList += $DurationSec }
    Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-Sta','-File',"`"$PSCommandPath`"") + $argsList | Out-Null
    return
  }

  $ErrorActionPreference = 'Stop'
  Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase

  $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None" AllowsTransparency="True" Background="#00FFFFFF"
        ShowInTaskbar="False" Topmost="True" ResizeMode="NoResize"
        WindowStartupLocation="CenterScreen" SizeToContent="WidthAndHeight">
  <Border CornerRadius="16" Background="#F0222222" Padding="22" Margin="0" >
    <Grid RenderTransformOrigin="0.5,0.5">
      <Grid.RenderTransform>
        <ScaleTransform ScaleX="1" ScaleY="1"/>
      </Grid.RenderTransform>
      <TextBlock x:Name="Msg" TextWrapping="Wrap" TextAlignment="Center"
                 Foreground="White" FontFamily="Segoe UI" FontSize="22" />
    </Grid>
  </Border>
</Window>
"@

  [xml]$xml = $xaml
  $reader  = New-Object System.Xml.XmlNodeReader $xml
  $window  = [Windows.Markup.XamlReader]::Load($reader)

  $msg = $window.FindName('Msg')
  $msg.Text = $Text

  # Estado inicial
  $window.Opacity = 0

  # Animaciones
  $window.Loaded.Add({
    param($s, $e)

    # Efecto "pop" + fundido
    $easeIn  = New-Object System.Windows.Media.Animation.QuadraticEase
    $easeOut = New-Object System.Windows.Media.Animation.QuadraticEase
    $easeOut.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut

    $fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation(0,1,[TimeSpan]::FromMilliseconds(250))
    $fadeIn.EasingFunction = $easeIn
    $s.BeginAnimation([System.Windows.Window]::OpacityProperty, $fadeIn)

    $scaleAnim = New-Object System.Windows.Media.Animation.DoubleAnimation(0.9,1,[TimeSpan]::FromMilliseconds(200))
    $scaleAnim.EasingFunction = $easeOut
    $grid = ($s.Content) # Border -> Grid
    $grid.RenderTransform.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $scaleAnim)
    $grid.RenderTransform.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $scaleAnim)

    # Programar cierre con desvanecimiento
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds($DurationSec)
    $timer.Add_Tick({
      $timer.Stop()
      $fadeOut = New-Object System.Windows.Media.Animation.DoubleAnimation(1,0,[TimeSpan]::FromMilliseconds(220))
      $fadeOut.Completed.Add({ $s.Close() })
      $s.BeginAnimation([System.Windows.Window]::OpacityProperty, $fadeOut)
    })
    $timer.Start()
  })

  $null = $window.ShowDialog()
}
catch {
  Write-Error ("Error: " + $_.Exception.Message)
}
`````
