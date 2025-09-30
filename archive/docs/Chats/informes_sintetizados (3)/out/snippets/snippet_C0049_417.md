```

## 3) Null-safety en el Markdown (evita choques con StrictMode)
**Patrón**: envuelve cada acceso potencialmente nulo en un `if (...) { ... } else { 'n/a' }`.  
Te dejo los **tres más sensibles** (aplica el mismo patrón al resto):

~~~~~
```