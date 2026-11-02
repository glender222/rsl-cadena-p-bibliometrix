# Cadena P · Bibliometrix en R

Flujo de análisis exclusivamente en R con **bibliometrix**, sin Python y sin enriquecimiento de metadatos ni incorporación de publicaciones externas.

## Compartir y descargar

Este repositorio contiene los cinco exports originales, los scripts de R, las tablas, los objetos R, los gráficos y el atlas PDF. Para consultar los resultados **no necesitas instalar R**.

- [Descargar todo el proyecto en ZIP](https://github.com/glender222/rsl-cadena-p-bibliometrix/archive/refs/heads/main.zip).
- [Abrir el atlas completo: 14 figuras, 15 páginas](resultados/Atlas_bibliometrico_Cadena_P.pdf).
- [Ver las figuras PNG, PDF y SVG](resultados/graficos/).

**Colección:** 738 registros exportados → 637 documentos únicos, tras consolidar 101 duplicados. Se conservó toda la colección aportada; no representa un corpus final de estudios incluidos tras cribado.

La red siguiente combina palabras clave de autor y términos de indexación (`KW_Merged`) disponibles en **181 de los 637 documentos**. Muestra 65 términos, 1200 enlaces y 5 clústeres calculados con bibliometrix. El diseño se inspira en VOSviewer y se genera íntegramente desde R.

![Red de coocurrencia generada en R con bibliometrix](resultados/graficos/14_red_coocurrencia_KW_Merged_estilo_VOS.png)

## Obtener una copia con Git

```bash
git clone https://github.com/glender222/rsl-cadena-p-bibliometrix.git
cd rsl-cadena-p-bibliometrix
```

## Ver los resultados

- [Atlas completo](resultados/Atlas_bibliometrico_Cadena_P.pdf).
- [Figuras y métodos](resultados/LEEME_RESULTADOS.md).
- [Gráficos individuales](resultados/graficos/).
- [Tablas y coordenadas](resultados/tablas/).

## Volver a ejecutar

Desde esta carpeta:

```bash
./ejecutar.sh
```

R instala dependencias en `~/.local/share/cadena-p/R-library`. También puede aprovechar paquetes de `~/R/library`. No se modifican los cinco exports originales de `P/`.

En Debian 13, si faltan encabezados de desarrollo de curl/OpenSSL/libuv, se pueden obtener dependencias R precompiladas **sin sudo**:

```bash
bash scripts/dependencias_debian.sh
Rscript scripts/instalar.R
./ejecutar.sh
```

Se requiere R 4.5 o compatible, fuentes DejaVu Sans y las bibliotecas gráficas del sistema. Las versiones efectivamente utilizadas quedan registradas en `resultados/auditoria/sessionInfo.txt` y `resultados/tablas/versiones_paquetes.csv`.

## Scripts

1. `01_importar.R`: lectura de los cinco exports y mapeo a tags de bibliometrix.
2. `02_depurar.R`: deduplicación conservadora y cobertura de metadatos.
3. `03_graficos.R`: análisis descriptivo, redes, MCA, clustering y mapa temático.
4. `04_flujos_acoplamiento.R`: tres campos nativo/interactivo y acoplamiento.
5. `05_entrega.R`: verificaciones independientes, atlas PDF y guía de resultados.
6. `06_red_estilo_vos.R`: redes de coocurrencia con enlaces curvos y etiquetas centradas; admite `DE` o `KW_Merged`.

Las funciones de bibliometrix empleadas incluyen `convert2df`, `metaTagExtraction`, `biblioAnalysis`, `cocMatrix`, `biblioNetwork`, `networkPlot`, `conceptualStructure`, `thematicMap` y `threeFieldsPlot`. La presentación final se ajusta con herramientas gráficas de R; los valores estadísticos se conservan.

## Ajustar el aspecto

### Red con composición similar a VOSviewer

Calculada en R con `biblioNetwork()` y `networkPlot()`. Se conserva el número de comunidades de Louvain; se acomodan las posiciones gráficas y etiquetas centradas, con enlaces curvos y colores por comunidad. No se emplea VOSviewer ni se añaden términos o enlaces.

```bash
# Autor + indexación: 181 documentos con estos metadatos; versión más densa.
Rscript scripts/06_red_estilo_vos.R KW_Merged
# Solo palabras clave de autor: 134 documentos con DE.
Rscript scripts/06_red_estilo_vos.R DE
```

Los archivos empiezan con `14_red_coocurrencia_KW_Merged_estilo_VOS` y `13_red_coocurrencia_estilo_VOS`, respectivamente, en PNG de 300 ppp, SVG y PDF. Las coordenadas y los enlaces verificados están en `resultados/tablas/`; los objetos nativos de bibliometrix, en `resultados/objetos/`.

- Paleta, tipografía y tamaños de exportación: `scripts/00_config.R`.
- Coordenadas de nodos y nube: CSV de `resultados/tablas/`.
- Redes: parámetros `n`, `minfreq`, `minedge` en `03_graficos.R`.
- Etiquetas: `geom_text_repel` con semilla fija. Sus líneas indican el punto original.
- Tres campos: posiciones de nodos y cintas en `04_flujos_acoplamiento.R`.

No mover las coordenadas factoriales para cambiar la interpretación del análisis. El archivo `coordenadas_factoriales_MCA.csv` guarda los valores calculados por bibliometrix.
