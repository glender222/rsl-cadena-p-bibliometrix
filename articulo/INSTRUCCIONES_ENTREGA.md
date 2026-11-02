# Incorporación del manuscrito completo al repositorio

Esta carpeta replica la estructura de `articulo/` del repositorio `rsl-cadena-p-bibliometrix`. Las cifras, tablas y figuras ya están calculadas. No deben recalcularse ni editarse a mano.

## 1. Archivos que se copian tal cual

| Origen en esta carpeta | Destino en el repositorio |
|---|---|
| `articulo/manuscrito.tex` | `articulo/manuscrito.tex` (reemplaza al actual) |
| `articulo/secciones/*.tex` | `articulo/secciones/` (carpeta nueva) |
| `articulo/tablas/*.tex` | `articulo/tablas/` (carpeta nueva) |
| `articulo/figuras/*.pdf` | `articulo/figuras/` |
| `articulo/figuras/prisma_rsl.tex` | `articulo/figuras/` (fuente del diagrama; no se compila con el manuscrito) |

`referencias.bib`, `sn-jnl.cls` y `sn-mathphys-num.bst` no cambian.

## 2. Cambios en `manuscrito.tex`

Respecto de la versión del repositorio, solo cambian dos cosas:

- El comentario de la línea 2.
- Antes de `\bibliography{referencias}` se añadieron estos `\input`:

```latex
\input{secciones/01_cierre_introduccion}   % último párrafo de la introducción
\input{secciones/02_antecedentes}
\input{secciones/03_metodo}
\input{secciones/04_resultados}
\input{secciones/05_discusion}               % incluye Amenazas a la validez y Conclusiones
\FloatBarrier
\input{secciones/06_final}                   % declaraciones y apéndice
```

El preámbulo, los autores, el resumen y la introducción quedan igual. La referencia `\ref{tab:rq}` de la introducción ya resuelve, porque `tab:rq` está en `tablas/tab_rq.tex`.

## 3. Ubicación de cada tabla y figura

| Etiqueta | Archivo | Sección |
|---|---|---|
| `tab:revisiones` | `tablas/tab_revisiones.tex` | 2.3 Revisiones relacionadas |
| `tab:proceso` | `tablas/tab_proceso.tex` | 3 Método (inicio) |
| `tab:rq` | `tablas/tab_rq.tex` | 3.1 Preguntas de investigación |
| `tab:bases` | `tablas/tab_bases.tex` | 3.2.1 Fuentes de información |
| `tab:cadena` | `tablas/tab_cadena.tex` | 3.2.2 Cadena de búsqueda |
| `tab:inclusion`, `tab:exclusion` | `tablas/tab_inclusion.tex`, `tablas/tab_exclusion.tex` | 3.3 Criterios de selección |
| `tab:calidad` | `tablas/tab_calidad_preguntas.tex` | 3.4 Evaluación de la calidad |
| `tab:extraccion` | `tablas/tab_extraccion.tex` | 3.5 Extracción de datos |
| `fig:prisma` | `figuras/prisma_rsl.pdf` | 4 Resultados (inicio) |
| `fig:anio`, `tab:sedes` | `figuras/fig_anio.pdf`, `tablas/tab_sedes.tex` | 4.1 Distribución de las publicaciones |
| `tab:calidadres` | `tablas/tab_calidad_resultados.tex` | 4.2 Calidad de los estudios |
| `fig:estrategias`, `tab:estrategias` | `figuras/fig_estrategias.pdf`, `tablas/tab_estrategias.tex` | 4.3 RQ1 |
| `fig:contramedidas`, `tab:contramedidas` | `figuras/fig_contramedidas.pdf`, `tablas/tab_contramedidas.tex` | 4.4 RQ2 |
| `tab:familias`, `fig:recuperacion`, `tab:matriz`, `tab:orientacion` | `tablas/tab_familias.tex`, `figuras/fig_recuperacion.pdf`, `tablas/tab_matriz.tex`, `tablas/tab_orientacion.tex` | 4.5 RQ3 |
| `tab:referencias` | `tablas/tab_referencias.tex` | 4.6 RQ4 |
| `tab:apnucleo` | `tablas/tab_apendice_nucleo.tex` | Apéndice A |

## 4. Reglas de edición

- Las tablas no llevan códigos internos (identificadores de estudio, de pregunta de calidad ni de categoría). Los estudios se citan con `\cite{}` y las categorías se escriben con su nombre completo.
- Los textos marcados con `\pend{...}` son datos que debe completar el equipo:
  - registro del protocolo;
  - declaración de uso de herramientas de IA;
  - alcance de la verificación de la extracción;
  - repositorio del material suplementario;
  - declaraciones finales.
- La sección bibliométrica no está incluida. Cuando se incorpore, debe describirse como un análisis del corpus de búsqueda (637 documentos únicos), no de los 64 estudios incluidos. También debe indicar que difiere en un registro de SpringerLink (455 en el repositorio frente a 456 en la selección).

## 5. Compilación

`bash compilar-articulo.sh`. El manuscrito se probó con `pdflatex` y `bibtex`, con el mismo preámbulo y los paquetes de `texlive-lang-spanish`: compila sin errores y tiene 35 páginas.
