# Entorno de redacción

El archivo principal es `manuscrito.tex`. La redacción comienza en
`\section{Introducción}\label{sec:intro}`. El título, los autores, el resumen y
las palabras clave están en el mismo archivo, antes de esa sección.

## Trabajar y compilar

Abrir la carpeta completa del repositorio en VS Code, con Docker iniciado y la
extensión LaTeX Workshop instalada. Al guardar un archivo LaTeX se ejecuta la
receta Docker. También se puede compilar con **Ctrl+Shift+B** o, desde la raíz:

```bash
bash compilar-articulo.sh
```

El resultado siempre se actualiza en `articulo/build/manuscrito.pdf`. Los
archivos temporales quedan excluidos de Git. En otro equipo, el script construye
la imagen Docker si aún no existe.

Las citas se añaden a `referencias.bib` y se invocan con `\cite{clave}`. Las
imágenes del artículo van en `figuras/`. Los gráficos bibliométricos existentes
se consultan en `../resultados/graficos/` y sus métodos en
`../resultados/LEEME_RESULTADOS.md`.

## Punto de partida para la introducción

El texto actual es el fragmento importado de Rslunlearnable. Sus cifras,
afirmaciones, tabla y referencias pertenecen a ese manuscrito; aún requieren
revisión para este artículo. Los cuatro enlaces internos a secciones posteriores
siguen pendientes y aparecen como `??` en el PDF.

La redacción se desarrollará desde el contexto y el problema, pasando por los
antecedentes y el vacío de investigación, hasta el objetivo y las preguntas de
investigación. Cada afirmación y cifra deberá apoyarse en los documentos y datos
aportados para este trabajo. Los 637 documentos únicos del análisis bibliométrico
son la colección exportada depurada; no constituyen por sí solos estudios
incluidos tras un cribado de RSL.
