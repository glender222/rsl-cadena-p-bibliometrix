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

## Manuscrito completo

Se incorporó `entrega_codex_RSL.zip`, aportado por el equipo, conservando sus
textos, cifras, tablas y figuras. El archivo principal mantiene el título, los
autores completos, la afiliación, el resumen y la introducción. Incluye además:

- `secciones/01_cierre_introduccion.tex`: cierre de la introducción.
- `secciones/02_antecedentes.tex`: antecedentes.
- `secciones/03_metodo.tex`: método.
- `secciones/04_resultados.tex`: resultados.
- `secciones/05_discusion.tex`: discusión, amenazas a la validez y conclusiones.
- `secciones/06_final.tex`: declaraciones y apéndice.

Las 18 tablas están en `tablas/`; las cinco figuras PDF y la fuente del diagrama
PRISMA están en `figuras/`. `referencias.bib` contiene las 69 entradas citadas.
La tabla de preguntas de investigación ya está incluida y su enlace desde la
introducción tiene destino. Las notas del paquete recibido se conservan en
`INSTRUCCIONES_ENTREGA.md` como documentación de origen.

Los campos marcados con `\pend{...}` son pendientes declarados por el equipo,
incluidas las declaraciones finales y los datos del material suplementario.
Las cifras y afirmaciones se trasladaron sin recalcularlas ni validarlas contra
la sábana, que no está incluida en este ZIP.

La redacción se desarrollará desde el contexto y el problema, pasando por los
antecedentes y el vacío de investigación, hasta el objetivo y las preguntas de
investigación. Cada afirmación y cifra deberá apoyarse en los documentos y datos
aportados para este trabajo. Los 637 documentos únicos del análisis bibliométrico
son la colección exportada depurada; no constituyen por sí solos estudios
incluidos tras un cribado de RSL.
