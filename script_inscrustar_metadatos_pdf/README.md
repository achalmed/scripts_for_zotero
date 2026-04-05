# Zotero PDF Metadata Embedder — v8.0

Sistema de dos scripts para exportar metadatos de Zotero e incrustarlos
directamente en los archivos PDF de tu biblioteca, sin alterar el contenido
de los documentos.

---

## Índice

1. [Descripción general](#descripción-general)
2. [Requisitos](#requisitos)
3. [Estructura de archivos](#estructura-de-archivos)
4. [Paso 1 — Script de Zotero (exportar metadatos)](#paso-1--script-de-zotero)
5. [Paso 2 — Script bash (incrustar metadatos)](#paso-2--script-bash)
6. [Modos de uso del script bash](#modos-de-uso-del-script-bash)
7. [Metadatos que se incrustan](#metadatos-que-se-incrustan)
8. [¿Es seguro para mis PDFs?](#es-seguro-para-mis-pdfs)
9. [Acelerar con GNU parallel](#acelerar-con-gnu-parallel)
10. [Verificar metadatos incrustados](#verificar-metadatos-incrustados)
11. [Solución de problemas](#solución-de-problemas)
12. [Flujo de trabajo completo (resumen rápido)](#flujo-de-trabajo-completo)

---

## Descripción general

El sistema consta de **dos scripts independientes** que trabajan en secuencia:

```
[Zotero]                          [Terminal]
   │                                  │
   │  zotero_export_metadata.js       │  embed_pdf_metadata.sh
   │                                  │
   ▼                                  ▼
Lee metadatos de         Lee cada zotero_metadata.json
cada ítem Zotero    →    junto al PDF y usa exiftool
                         para incrustar los metadatos
                         directamente en el PDF
```

**Por qué dos scripts separados:**
Zotero ejecuta JavaScript en su propio entorno y no tiene acceso directo
a herramientas del sistema como `exiftool`. El script JS solo escribe un
archivo JSON con los metadatos. Luego el script bash, corriendo en tu
terminal normal, usa `exiftool` para hacer el trabajo real sobre los PDFs.

---

## Requisitos

**Sistema operativo:** Arch Linux (o cualquier distro con pacman)

**Herramientas necesarias:**

```bash
# Instalar dependencias
sudo pacman -S perl-image-exiftool jq

# Opcional pero muy recomendado para bibliotecas grandes
sudo pacman -S parallel
```

| Herramienta | Para qué se usa                                        |
| ----------- | ------------------------------------------------------ |
| `exiftool`  | Leer y escribir metadatos en PDFs (XMP, PDF info dict) |
| `jq`        | Parsear los archivos JSON generados por Zotero         |
| `parallel`  | Procesar múltiples PDFs en paralelo (más rápido)       |

---

## Estructura de archivos

Después de ejecutar el Paso 1, tu biblioteca quedará así:

```
biblioteca/
└── Yulino, Anastacio Clemente/
    ├── Ciclos economicos reales (3704)/
    │   ├── Ciclos economicos reales - Yulino, Anastacio Clemente.pdf
    │   ├── zotero_metadata.json    ← GENERADO por el script JS
    │   ├── cover.jpg
    │   └── metadata.opf
    ├── Crecimiento economico i (3705)/
    │   ├── Crecimiento economico i - Yulino, Anastacio Clemente.pdf
    │   ├── zotero_metadata.json    ← GENERADO por el script JS
    │   ├── cover.jpg
    │   └── metadata.opf
    └── ...
```

**Formato del archivo `zotero_metadata.json`:**

```json
{
  "title": "Ciclos economicos reales",
  "authors": ["Anastacio Clemente Yulino"],
  "editors": [],
  "abstract": "Resumen del documento...",
  "tags": ["macroeconomia", "ciclos"],
  "publisher": "Universidad Nacional",
  "date": "2023",
  "year": "2023",
  "doi": "",
  "url": "",
  "isbn": "",
  "issn": "",
  "identifier": "",
  "itemType": "Document",
  "rawItemType": "document",
  "source": "",
  "volume": "",
  "issue": "",
  "pages": "",
  "language": "es",
  "rights": "",
  "series": "",
  "place": "Lima",
  "edition": "",
  "numPages": "",
  "callNumber": "",
  "zoteroKey": "ABCD1234",
  "zoteroId": "3704",
  "exportedAt": "2025-01-15T10:30:00.000Z",
  "pdf_filename": "Ciclos economicos reales - Yulino, Anastacio Clemente.pdf",
  "pdf_path": "/home/achalmaedison/Documents/biblioteca/Yulino, Anastacio Clemente/Ciclos economicos reales (3704)/Ciclos economicos reales - Yulino, Anastacio Clemente.pdf"
}
```

---

## Paso 1 — Script de Zotero

**Archivo:** `zotero_export_metadata.js`

### Instrucciones

1. Abre Zotero.
2. Selecciona los ítems que deseas procesar:
   - **Toda la biblioteca:** `Ctrl+A` en la vista de ítems.
   - **Una colección:** Haz clic en la colección y luego `Ctrl+A`.
   - **Ítems individuales:** Selecciona manualmente con clic / Shift+clic.
3. Ve a **Herramientas → Ejecutar JavaScript** (o `Tools → Run JavaScript`).
4. Borra el contenido del editor que aparece.
5. Pega el contenido completo de `zotero_export_metadata.js`.
6. Haz clic en **Ejecutar** (o `Run`).
7. Espera el cuadro de confirmación con el resumen.

### Qué hace internamente

- Itera sobre cada ítem seleccionado (omite notas y adjuntos directos).
- Para cada ítem que tenga al menos un PDF adjunto:
  - Extrae todos los campos de metadatos disponibles en Zotero.
  - Determina la carpeta donde está el PDF.
  - Escribe un archivo `zotero_metadata.json` en esa misma carpeta.
- Al final muestra un resumen: cuántos JSON generó, cuántos omitió y errores.

### Notas importantes

- Si un ítem tiene **varios PDFs adjuntos**, se genera un JSON por cada PDF
  (en la carpeta correspondiente de cada adjunto).
- Si ejecutas el script varias veces, el JSON existente se **sobreescribe**
  con los metadatos más recientes de Zotero. Esto es útil para actualizar.
- Los ítems que son notas (`isNote()`) o adjuntos directos (`isAttachment()`)
  se omiten automáticamente.

---

## Paso 2 — Script bash

**Archivo:** `embed_pdf_metadata.sh`

**Instalación (una sola vez):**

```bash
# Copiar el script a tu home
cp embed_pdf_metadata.sh ~/embed_pdf_metadata.sh

# Dar permisos de ejecución
chmod +x embed_pdf_metadata.sh
```

### Instrucciones

```bash
# Modo básico: procesar toda la biblioteca
bash embed_pdf_metadata.sh ~/Documents/biblioteca

# O si ya estás en la carpeta de la biblioteca:
cd ~/Documents/biblioteca
bash ~/embed_pdf_metadata.sh
```

---

## Modos de uso del script bash

### Toda la biblioteca

```bash
bash ~/embed_pdf_metadata.sh ~/Documents/biblioteca

o

./embed_pdf_metadata.sh ../../../Documents/biblioteca
```

Busca recursivamente **todos** los `zotero_metadata.json` dentro de
`~/Documents/biblioteca` y procesa el PDF correspondiente en cada carpeta.

### Una carpeta de autor específica

```bash
bash ~/embed_pdf_metadata.sh ~/Documents/biblioteca/Yulino,\ Anastacio\ Clemente
```

Solo procesa los PDFs del autor indicado.

### Varias carpetas a la vez

```bash
bash ~/embed_pdf_metadata.sh \
  ~/Documents/biblioteca/Zenon,\ Quispe\ Misaico \
  ~/Documents/biblioteca/Zaida,\ Quiroz\ Cornejo \
  ~/Documents/biblioteca/Yuri,\ Galvez\ Gastelu
```

### Con comillas (más fácil para rutas con espacios)

```bash
bash ~/embed_pdf_metadata.sh \
  "/home/achalmaedison/Documents/biblioteca/Yulino, Anastacio Clemente" \
  "/home/achalmaedison/Documents/biblioteca/Zenon, Quispe Misaico"
```

### Desde el directorio actual

```bash
cd "/home/achalmaedison/Documents/biblioteca/Youel, Rojas Zea"
bash ~/embed_pdf_metadata.sh
# Procesa todos los zotero_metadata.json en la carpeta actual y subcarpetas
```

---

## Metadatos que se incrustan

El script incrusta metadatos en **dos niveles** del PDF para máxima compatibilidad:

### 1. Diccionario de información PDF (PDF Info Dict)

Campos básicos legibles por cualquier lector de PDF:

| Campo exiftool | Contenido                             |
| -------------- | ------------------------------------- |
| `-Title`       | Título del documento                  |
| `-Author`      | Autores separados por "; "            |
| `-Description` | Resumen / abstract                    |
| `-Subject`     | Resumen (campo alternativo)           |
| `-Keywords`    | Etiquetas Zotero separadas por "; "   |
| `-Publisher`   | Editorial / institución               |
| `-Identifier`  | DOI, ISBN, ISSN o URL                 |
| `-Source`      | Revista, libro, conferencia           |
| `-Type`        | Tipo de ítem (Book, Journal Article…) |
| `-Language`    | Idioma del documento                  |
| `-Rights`      | Derechos de autor                     |
| `-CreateDate`  | Fecha de publicación                  |

### 2. Metadatos XMP (Extensible Metadata Platform)

Estándar moderno embebido como XML dentro del PDF. Compatible con Calibre,
Adobe Acrobat, Okular, Evince y herramientas de gestión documental:

| Namespace   | Campos                                                                                            |
| ----------- | ------------------------------------------------------------------------------------------------- |
| `XMP-dc`    | Title, Creator, Description, Subject, Publisher, Type, Language, Rights, Identifier, Date, Source |
| `XMP-prism` | Volume, Number (issue), StartingPage, IsPartOf (series), Edition                                  |

---

## ¿Es seguro para mis PDFs?

**Sí. El contenido de los PDFs no se modifica en absoluto.**

`exiftool` solo reescribe la sección de metadatos del archivo PDF, que es
una estructura separada del contenido (páginas, imágenes, texto, fuentes).
El proceso es:

1. `exiftool` lee el PDF completo.
2. Modifica únicamente el bloque de metadatos XMP y el diccionario Info.
3. Escribe el archivo de vuelta (con `-overwrite_original` lo hace
   atómicamente: crea un temp, lo renombra, sin dejar archivos `.pdf_original`).

**Casos donde puede haber un problema (raros):**

- PDFs **con contraseña de propietario** que impide modificaciones.
  `exiftool` reportará un error, el PDF no se tocará.
- PDFs **muy dañados o malformados**. Error reportado, sin cambios.
- PDFs **de solo lectura** en el sistema de archivos. Verificar permisos.

**Para mayor seguridad**, si quieres hacer backups antes de correr el script
por primera vez, elimina `-overwrite_original` del script bash. Esto hará
que `exiftool` deje archivos `*.pdf_original` como respaldo.

---

## Acelerar con GNU parallel

Con una biblioteca de miles de PDFs, el procesamiento secuencial puede
tardar varios minutos. Con `parallel` se usa todos los núcleos del CPU:

```bash
# Instalar
sudo pacman -S parallel

# El script lo detecta automáticamente y lo usa
bash ~/embed_pdf_metadata.sh ~/Documents/biblioteca
# Salida: "⚡ Usando GNU parallel (8 núcleos)"
```

**Rendimiento estimado** (Intel i5, SSD):

- Sin parallel: ~2-3 PDFs/segundo
- Con parallel (8 núcleos): ~12-15 PDFs/segundo
- Para 5837 PDFs: ~7 min sin parallel / ~2 min con parallel

---

## Verificar metadatos incrustados

Después de ejecutar el script, verifica que los metadatos se incrustaron:

```bash
# Campos básicos
exiftool -Title -Author -Keywords -Description -Publisher \
  "/home/achalmaedison/Documents/biblioteca/Yulino, Anastacio Clemente/Ciclos economicos reales (3704)/Ciclos economicos reales - Yulino, Anastacio Clemente.pdf"

# Todos los metadatos XMP
exiftool -XMP:all <archivo.pdf>

# Solo el bloque de información PDF
exiftool -PDF:all <archivo.pdf>

# Todo junto (muy detallado)
exiftool -a -u -g1 <archivo.pdf>
```

**Compatibilidad con Calibre:**
Calibre lee los campos XMP-dc automáticamente. Después de incrustar,
si agregas el PDF a Calibre, debería detectar título, autor, etc.

---

## Solución de problemas

### "No se encontraron archivos zotero_metadata.json"

```
⚠️  No se encontraron archivos 'zotero_metadata.json'.
```

**Causa:** El script de Zotero no se ejecutó aún, o se ejecutó en una
ruta diferente a donde apunta el script bash.

**Solución:**

1. Verifica que ejecutaste el script JS en Zotero con ítems seleccionados.
2. Busca manualmente si existen los JSON:
   ```bash
   find ~/Documents/biblioteca -name "zotero_metadata.json" | head -5
   ```
3. Si no aparecen, vuelve al Paso 1.

---

### "exiftool: Error" en algún PDF

```
❌ Error al procesar
```

**Causas comunes y soluciones:**

```bash
# 1. Ver el error exacto (quitar -q del script para diagnóstico)
exiftool -Title="Test" -overwrite_original "/ruta/al/archivo.pdf"

# 2. Verificar permisos
ls -la "/ruta/al/archivo.pdf"
chmod u+w "/ruta/al/archivo.pdf"  # dar permiso de escritura si es necesario

# 3. PDF con contraseña
# exiftool reportará: "Error: File is encrypted"
# No hay solución sin la contraseña.

# 4. PDF dañado
# Verificar integridad:
exiftool "/ruta/al/archivo.pdf" 2>&1 | grep -i error
```

---

### El script de Zotero no genera JSON (no hay errores pero tampoco archivos)

**Causa:** Los ítems seleccionados no tienen PDFs adjuntos _locales_.
Puede que los adjuntos estén enlazados como URL o no descargados.

**Solución:**

1. En Zotero, haz clic derecho en el ítem → "Mostrar archivo adjunto" para
   verificar que el PDF esté en disco.
2. Si el adjunto es una URL, descárgalo primero: clic derecho → "Guardar copia".
3. Verifica que la ruta del PDF apunte a tu carpeta `biblioteca`.

---

### Los metadatos no aparecen en el lector de PDF

Algunos lectores (Evince antiguo, Acrobat Reader básico) no muestran todos
los campos XMP. Usa:

```bash
# Verificación definitiva con exiftool
exiftool -Title -Author -XMP-dc:Creator <archivo.pdf>
```

Si `exiftool` los muestra, los metadatos están ahí. El problema es el lector.
**Okular**, **Zathura** y **Adobe Acrobat** los muestran correctamente.

---

### Proceso muy lento

```bash
# Instalar parallel para procesamiento en paralelo
sudo pacman -S parallel

# Verificar cuántos núcleos tienes
nproc

# Correr de nuevo el script
bash ~/embed_pdf_metadata.sh ~/Documents/biblioteca
```

---

### Re-exportar solo algunos ítems

Si actualizas metadatos en Zotero (corriges un título, agregas tags, etc.):

1. En Zotero, selecciona solo los ítems modificados.
2. Ejecuta el script JS → sobreescribe solo esos `zotero_metadata.json`.
3. Ejecuta el script bash apuntando a la carpeta del autor específico:
   ```bash
   bash ~/embed_pdf_metadata.sh "/home/achalmaedison/Documents/biblioteca/Yulino, Anastacio Clemente"
   ```

---

## Flujo de trabajo completo

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUJO COMPLETO v5.0                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  PASO 1 — En Zotero:                                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  1. Abre Zotero                                     │   │
│  │  2. Selecciona ítems (Ctrl+A para todos)            │   │
│  │  3. Herramientas → Ejecutar JavaScript              │   │
│  │  4. Pega zotero_export_metadata.js → Ejecutar       │   │
│  │  5. Confirma el mensaje de éxito                    │   │
│  │                                                     │   │
│  │  Resultado: zotero_metadata.json en cada carpeta    │   │
│  └─────────────────────────────────────────────────────┘   │
│                          │                                  │
│                          ▼                                  │
│  PASO 2 — En el terminal:                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  # Toda la biblioteca                               │   │
│  │  bash ~/embed_pdf_metadata.sh ~/Documents/biblioteca│   │
│  │                                                     │   │
│  │  # O una carpeta específica:                        │   │
│  │  bash ~/embed_pdf_metadata.sh \                     │   │
│  │    "~/Documents/biblioteca/Yulino, Anastacio Clemente"  │
│  │                                                     │   │
│  │  Resultado: metadatos incrustados en cada PDF       │   │
│  └─────────────────────────────────────────────────────┘   │
│                          │                                  │
│                          ▼                                  │
│  VERIFICAR:                                                 │
│  exiftool -Title -Author -Keywords <archivo.pdf>            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Comandos de instalación rápida (copia y pega)

```bash
# 1. Instalar dependencias
sudo pacman -S perl-image-exiftool jq parallel

# 2. Copiar el script bash a tu home
cp embed_pdf_metadata.sh ~/embed_pdf_metadata.sh
chmod +x ~/embed_pdf_metadata.sh

# 3. En Zotero: ejecutar zotero_export_metadata.js (ver Paso 1)

# 4. Incrustar metadatos en toda la biblioteca
bash ~/embed_pdf_metadata.sh ~/Documents/biblioteca


o

# Copiar a tu carpeta persobalizada
cp embed_pdf_metadata.sh ~/Documents/scripts_for_zotero/script_inscrustar_metadatos_pdf/embed_pdf_metadata.sh

# Probar primero en modo simulación (dry-run, sin tocar PDFs)
bash ~/embed_pdf_metadata.sh --dry-run ../../../Documents/biblioteca

# Ejecutar real en toda la biblioteca
bash ~/embed_pdf_metadata.sh ../../../Documents/biblioteca

# Con log para revisar después
bash ~/embed_pdf_metadata.sh --log ~/zotero_embed.log ../../../Documents/biblioteca

# Verificar un PDF después
exiftool -Title -Author -Keywords -XMP-dc:Creator "/ruta/al/archivo.pdf"
```

Nuevo modo --repair-only: repara los PDFs malformados sin tocar metadatos, útil para limpiar la biblioteca primero.

---

_Generado para Archcraft x86_64 · Biblioteca: `/home/achalmaedison/Documents/biblioteca`_
_Compatible con: Arch Linux, Manjaro, EndeavourOS y cualquier distro con pacman_
