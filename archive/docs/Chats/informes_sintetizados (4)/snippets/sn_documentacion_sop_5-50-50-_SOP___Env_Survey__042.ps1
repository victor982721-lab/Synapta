$encInfo.Default_CodePage    = [Text.Encoding]::Default.CodePage
$encInfo.ConsoleOut_CodePage = try { [Console]::OutputEncoding.CodePage } catch { $null }
$encInfo.Utf8_CP65001_Avail  = try { [Text.Encoding]::GetEncoding(65001) | Out-Null; $true } catch { $false }