[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework
$window = New-Object System.Windows.Window
$window.Title = "Mensaje Animado"
$window.Width = 300
$window.Height = 200
$textBlock = New-Object System.Windows.Controls.TextBlock
$textBlock.Text = "¡Hola Mundo! 😜"
$window.Content = $textBlock
$animation = New-Object System.Windows.Media.Animation.DoubleAnimation
$animation.From = 0
$animation.To = 1
$animation.Duration = New-Object System.Windows.Duration([TimeSpan]::FromSeconds(1))
[System.Windows.Media.Animation.Storyboard]::SetTarget($animation, $textBlock)
[System.Windows.Media.Animation.Storyboard]::SetTargetProperty($animation, [System.Windows.PropertyPath]::new("Opacity"))
$storyboard = New-Object System.Windows.Media.Animation.Storyboard
$storyboard.Children.Add($animation)
$storyboard.Begin($window)
$window.ShowDialog()