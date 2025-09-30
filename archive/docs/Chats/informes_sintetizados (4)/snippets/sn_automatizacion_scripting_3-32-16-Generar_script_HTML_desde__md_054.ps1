# PS 7
pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit-CLEAN.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

# PS 5.1
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit-CLEAN.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

# Formatos alternos
.\PS-Env-Audit-CLEAN.ps1 -ReportPath "$env:USERPROFILE\Desktop\PS_Env_Report.json" -ReportFormat json
.\PS-Env-Audit-CLEAN.ps1 -ReportPath "$env:USERPROFILE\Desktop\PS_Env_Report.txt"  -ReportFormat txt