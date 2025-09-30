Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase
$XAML = @"
<Window x:Class="MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Animación" Width="400" Height="200" Topmost="True" ResizeMode="NoResize">
    <Grid>
        <TextBlock HorizontalAlignment="Center" VerticalAlignment="Center" FontSize="22" Name="textBlock">Me gusta la fiesta, pero con responsabilidad 😛</TextBlock>
    </Grid>
</Window>
"@
$Reader = New-Object System.Xml.XmlReaderSettings  
$Reader.ConformanceLevel = [System.Xml.ConformanceLevel]::Document
$StringReader = New-Object System.IO.StringReader($XAML)
$XamlReader = [System.Windows.Markup.XamlReader]::Load($StringReader)
$window = New-Object System.Windows.Window
$window.Content = $XamlReader
$animation = New-Object System.Windows.Media.Animation.DoubleAnimation
$animation.From = 0
$animation.To = 1
$animation.Duration = New-Object System.Windows.Duration([TimeSpan]::FromSeconds(1))
[System.Windows.Media.Animation.Storyboard]::SetTarget($animation, $window.Content.textBlock)
[System.Windows.Media.Animation.Storyboard]::SetTargetProperty($animation, [System.Windows.PropertyPath]::new("Opacity"))
$storyboard = New-Object System.Windows.Media.Animation.Storyboard
$storyboard.Children.Add($animation)
$storyboard.Begin($window)
$window.ShowDialog()