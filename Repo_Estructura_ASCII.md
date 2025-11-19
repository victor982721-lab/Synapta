
# Estructura general del proyecto "Neurologic"

Neurologic/
├── AGENTS.md                         # AGENTS general (Codex)
├── Politica_Cultural_y_Calidad.md    # Política cultural y de calidad
├── README.md                         # Índice normativo / info general
├── Core/                             # Librerías reutilizables “canon”
│   ├── AGENTS.md                     # Reglas específicas para Core
│   ├── README.md                     # Descripción rápida de los módulos Core
│   ├── FileSystem/
│   │   ├── Neurologic.Core.FileSystem.csproj
│   │   ├── src/
│   │   │   └── ...                   # Motores de FS, recorridos, etc.
│   │   └── tests/
│   │       └── ...                   # Pruebas de FileSystem
│   ├── Indexing/
│   │   ├── Neurologic.Core.Indexing.csproj
│   │   ├── src/
│   │   │   └── ...                   # Indexador genérico, estructuras, etc.
│   │   └── tests/
│   │       └── ...                   # Pruebas de Indexing
│   └── Search/
│       ├── Neurologic.Core.Search.csproj
│       ├── src/
│       │   └── ...                   # Motor de búsqueda genérico
│       └── tests/
│           └── ...                   # Pruebas de Search
└── Sandbox/
    ├── Ws_Insights/
    │   ├── AGENTS.md                 # AGENTS específico Ws_Insights
    │   ├── README.md                 # README del proyecto Ws_Insights
    │   ├── Ws_Insights.csproj        # App WPF multi-framework
    │   ├── docs/
    │   │   ├── filemap_ascii.txt
    │   │   └── table_hierarchy.json
    │   ├── csv/
    │   │   └── ...                   # Inventario de archivos
    │   ├── Scripts/
    │   │   └── ...                   # Scripts auxiliares
    │   └── src/
    │       └── ...                   # Código específico de la app
    └── OtrosProyectos/
        └── ...                       # Otros experimentos / apps