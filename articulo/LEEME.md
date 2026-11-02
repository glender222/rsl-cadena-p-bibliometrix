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

El texto actual contiene la portada, el resumen, las palabras clave y la
introducción de `manuscrito_RSL_fuentes`, aportado por el equipo. Se conserva la
bibliografía completa del archivo recibido para continuar la redacción; se
imprimen únicamente las referencias citadas. No se importaron las secciones
desde Antecedentes en adelante.

Los apellidos y la afiliación se completaron con los datos de la versión anterior;
también se recuperó la autoría de DR Soria Quijaite tal como figuraba allí. Se
mantienen el orden de los tres autores y el correo de correspondencia del archivo
recibido. La introducción remite a `tab:rq`, una tabla situada en
Método en el documento de origen; ese enlace quedará pendiente hasta incorporar
esa parte. Las cifras y afirmaciones se trasladaron sin recalcularlas ni
validarlas contra la sábana, que no se incluyó en esta carpeta de fuentes.

La redacción se desarrollará desde el contexto y el problema, pasando por los
antecedentes y el vacío de investigación, hasta el objetivo y las preguntas de
investigación. Cada afirmación y cifra deberá apoyarse en los documentos y datos
aportados para este trabajo. Los 637 documentos únicos del análisis bibliométrico
son la colección exportada depurada; no constituyen por sí solos estudios
incluidos tras un cribado de RSL.
