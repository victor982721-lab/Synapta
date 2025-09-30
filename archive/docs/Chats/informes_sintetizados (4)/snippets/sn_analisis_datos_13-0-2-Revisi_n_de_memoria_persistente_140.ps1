New-Item -ItemType Directory -Force -Path C:\YSD300A\base    | Out-Null
New-Item -ItemType Directory -Force -Path C:\YSD300A\p2406   | Out-Null

Copy-Item "C:\Users\VictorFabianVeraVill\Desktop\TBEA\01_Software\YSD_300AN\YSD300AN.exe" `
          -Destination "C:\YSD300A\base\YSD300AN.exe" -Force

Copy-Item "C:\Users\VictorFabianVeraVill\Desktop\TBEA\01_Software\300AN\YSD300AN-P2406.exe" `
          -Destination "C:\YSD300A\p2406\YSD300AN-P2406.exe" -Force