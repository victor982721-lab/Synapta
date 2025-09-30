### Entrada (user)

Ayudame a elaborar un plan de limpieza con el documento adjunto

### Salida (assistant)

{"content_type": "code", "language": "unknown", "response_format_name": null, "text": "import os, zipfile, json, re, io, sys, textwrap, shutil, pathlib, csv, datetime, traceback\r\n\r\nzip_path = \"/mnt/data/FileList_Users_20250921_020839.zip\"\r\nexists = os.path.exists(zip_path)\r\nexists, os.listdir(\"/mnt/data\")[:10]"}
