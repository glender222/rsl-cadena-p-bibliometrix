source('scripts/00_config.R')
M<-readRDS('resultados/objetos/corpus_bibliometrix.rds');raw<-readRDS('resultados/objetos/registros_antes_deduplicar.rds')
coverage<-read.csv('resultados/tablas/cobertura_campos.csv')
figs<-sort(list.files('resultados/graficos',pattern='\\.pdf$',full.names=TRUE))
stopifnot(length(figs)>=12)
# Independent frequency and pair checks directly against the deduplicated text fields.
K<-M[present(M$DE),];terms<-lapply(K$DE,function(s)unique(trimws(strsplit(s,';',fixed=TRUE)[[1]])))
manual<-sort(table(unlist(terms)),decreasing=TRUE)
reported<-read.csv('resultados/tablas/frecuencias_keywords_autor.csv')
stopifnot(!anyNA(manual[reported$termino]),all(as.numeric(manual[reported$termino])==reported$documentos))
N<-readRDS('resultados/objetos/red_coocurrencia_completa.rds')
node<-read.csv('resultados/tablas/02_coocurrencia_nodos.csv');ed<-read.csv('resultados/tablas/02_coocurrencia_enlaces.csv')
for(i in seq_len(nrow(ed))){a<-tolower(ed$from[i]);b<-tolower(ed$to[i]);expected<-sum(vapply(terms,function(t)a%in%tolower(t)&&b%in%tolower(t),logical(1)));stopifnot(expected==ed$weight[i])}
# Recount shared normalized references by set intersection, independently of matrix multiplication.
refs<-read.csv('resultados/tablas/documentos_referencias_normalizadas.csv')
refs<-split(refs$referencia_normalizada,refs$DOC_ID)
ce<-read.csv('resultados/tablas/12_acoplamiento_bibliografico_enlaces.csv')
for(i in seq_len(nrow(ce)))stopifnot(ce$weight[i]==length(intersect(refs[[ce$from[i]]],refs[[ce$to[i]]])))
# Confirm explicit label rectangles do not intersect in the final network coordinates.
for(id in c('02_coocurrencia','03_colaboracion_autores','04_colaboracion_paises','12_acoplamiento_bibliografico')){
  nn<-read.csv(paste0('resultados/tablas/',id,'_nodos.csv'))
  for(i in seq_len(nrow(nn)-1))for(j in (i+1):nrow(nn))stopifnot(!(abs(nn$label_x[i]-nn$label_x[j])<(nn$label_w[i]+nn$label_w[j])/2 & abs(nn$label_y[i]-nn$label_y[j])<(nn$label_h[i]+nn$label_h[j])/2))
}
stopifnot(all(vapply(strsplit(M$AU_CO[present(M$AU_CO)],';',fixed=TRUE),anyDuplicated,integer(1))==0))
# The MD5 hashes must be unchanged: no writes to the user's exports.
manifest<-read.csv('resultados/auditoria/archivos_originales.csv')
stopifnot(identical(as.character(manifest$md5),unname(tools::md5sum(manifest$archivo))))
writeLines(c('VALIDACIONES COMPLETADAS',paste('Registros brutos:',nrow(raw)),paste('Documentos unicos:',nrow(M)),paste('Filas de duplicados consolidadas:',nrow(raw)-nrow(M)),paste('Frecuencias de keywords verificadas:',length(manual)),paste('Enlaces de coocurrencia verificados:',nrow(ed)),paste('Enlaces de acoplamiento normalizado verificados:',nrow(ce)),'Cuatro redes: etiquetas sin interseccion de rectangulos','Paises: sin repeticiones dentro de cada documento','MD5 de los cinco exports: sin cambios','Coordenadas factoriales: proceden de conceptualStructure, sin desplazamiento estadistico','Semilla de disposicion y clustering: 20261101'),'resultados/auditoria/validaciones.txt')
writeLines(capture.output(sessionInfo()),'resultados/auditoria/sessionInfo.txt')
p<-installed.packages();csv(data.frame(paquete=p[,'Package'],version=p[,'Version'],biblioteca=p[,'LibPath']),'versiones_paquetes')
# Cover page, authored with R graphics. All subsequent pages retain vector charts.
cover<-'resultados/objetos/portada.pdf'
cairo_pdf(cover,width=14,height=10,family='DejaVu Sans',bg='white')
par(mar=c(0,0,0,0));plot.new();plot.window(c(0,1),c(0,1),xaxs='i',yaxs='i')
rect(0,.96,1,1,col='#258DAA',border=NA)
text(.07,.89,'CADENA P',adj=c(0,.5),cex=1.25,col='#258DAA',font=2)
text(.07,.81,'Atlas bibliométrico',adj=c(0,.5),cex=2.6,col='#192B3A',font=2)
text(.07,.735,'Colección de búsqueda exportada · R + bibliometrix',adj=c(0,.5),cex=1.2,col='#526574')
values<-c(nrow(raw),nrow(M),nrow(raw)-nrow(M),sum(present(M$DE)))
labels<-c('registros originales','documentos únicos','duplicados consolidados','con palabras clave de autor')
for(i in 1:4){x<-.07+(i-1)*.235;text(x,.605,format(values[i],big.mark=','),adj=c(0,.5),cex=2.4,font=2,col='#258DAA');text(x,.545,labels[i],adj=c(0,.5),cex=.85,col='#526574')}
segments(.07,.49,.93,.49,col='#DDE6EB')
notes<-c('ALCANCE Y LECTURA',sprintf('Se conservaron todos los documentos únicos de tus cinco exports (%s–%s).',min(M$PY,na.rm=TRUE),max(M$PY,na.rm=TRUE)),'La colección de búsqueda no equivale a los estudios incluidos tras el cribado de una RSL.',sprintf('Palabras clave de autor: %s documentos; keywords combinadas: %s; autores separables: %s.',sum(present(M$DE)),sum(present(M$KW_Merged)),sum(present(M$AU))),sprintf('Acoplamiento: %s documentos con referencias citadas. No es una búsqueda externa de citas.',sum(present(M$CR))),'Springer no aporta keywords, resúmenes ni referencias; sus autores concatenados no se adivinan.','Los años recientes pueden estar incompletos. Se respetaron los años presentes en los exports.','Las etiquetas se acomodan; las coordenadas del análisis factorial se mantienen intactas.')
y<-.425
for(i in seq_along(notes)){text(.07,y,notes[i],adj=c(0,1),cex=if(i==1).95 else .91,font=if(i==1)2 else 1,col=if(i==1)'#192B3A' else '#526574');y<-y-if(i==1).052 else .045}
text(.07,.045,paste('Elaborado con tus datos · 02/11/2026 · bibliometrix',packageVersion('bibliometrix')),adj=c(0,.5),cex=.8,col='#778A96')
dev.off()
pdftools::pdf_combine(c(cover,figs),output='resultados/Atlas_bibliometrico_Cadena_P.pdf')
# Markdown source accompanies the PDF and figures; no external data are embedded.
md<-c('# Bibliometría de la cadena P','',sprintf('**%s registros originales → %s documentos únicos; %s duplicados consolidados.**',nrow(raw),nrow(M),nrow(raw)-nrow(M)),'','Se analizaron exclusivamente los cinco archivos de `P/`. No se añadieron artículos, referencias, palabras clave ni afiliaciones de otras fuentes. Esta es la colección recuperada por la búsqueda; no se ha supuesto que todos los resultados cumplan criterios de inclusión de la RSL.','','## Entregables','','- `Atlas_bibliometrico_Cadena_P.pdf`: atlas de figuras.','- `graficos/`: cada gráfico en PNG de 300 ppp, PDF y SVG vectoriales.','- `interactivos/08_three_field_plot.html`: versión interactiva nativa del diagrama de tres campos (conservar la carpeta `lib/` junto al HTML).','- `tablas/`: corpus, trazabilidad, frecuencias, matrices de enlaces y coordenadas.','- `objetos/`: resultados R originales de bibliometrix.','- `auditoria/`: hashes originales, logs, validaciones y versiones.','','## Cobertura','','| Campo | Documentos | Cobertura |','|---|---:|---:|')
for(i in seq_len(nrow(coverage)))md<-c(md,sprintf('| %s | %s/%s | %.1f%% |',coverage$campo[i],coverage$registros[i],coverage$total[i],coverage$porcentaje[i]))
md<-c(md,'','## Figuras','')
for(f in figs){id<-sub('\\.pdf$','',basename(f));md<-c(md,paste0('### ',gsub('_',' ',id)),'',paste0('![',id,'](graficos/',id,'.png)'),'',paste0('[PDF](graficos/',id,'.pdf) · [SVG editable](graficos/',id,'.svg)'), '')}
md<-c(md,'## Métodos y límites','','1. **Importación.** Scopus se convierte también con `convert2df`. WoS XLS, IEEE y Springer se mapean a los tags de bibliometrix en R, sin consultar servicios externos. Se conservan los datos originales como objetos R y los cinco archivos quedan intactos.','2. **Duplicados.** Se agrupan DOI exactos normalizados y títulos exactos normalizados cuando no hay DOI incompatibles. No se aplica fusión difusa. Prioridad para campos escalares: Scopus, WoS, IEEE, Springer; keywords se unen sin duplicarlas. Los conflictos de año y citas se guardan en CSV.','3. **Autores.** Se unifican puntuación y formato apellido/iniciales cuando los delimitadores son explícitos. Los homónimos con iguales iniciales no quedan desambiguados. Los autores concatenados de Springer no se usan en las redes salvo que otra base aporte nombres separables para el mismo DOI/título.','4. **Palabras clave.** Se usa DE (author keywords), sin mezclarlo silenciosamente con términos de indexación. Solo se normalizan mayúsculas y espacios. No se añaden sinónimos, traducciones ni categorías temáticas elegidas manualmente. Cada documento cuenta como máximo una vez por término.','5. **Red conceptual.** `biblioNetwork` calcula coocurrencias; Louvain agrupa con pesos de fuerza de asociación. La figura limita términos y enlaces mediante umbrales visibles. Las posiciones se calculan con Fruchterman–Reingold y semilla fija.','6. **Factorial.** `conceptualStructure(method="MCA")` calcula coordenadas y agrupamiento jerárquico con enlace promedio; el número de grupos se selecciona con la regla automática de bibliometrix. No se desplazan puntos para imitar una figura de referencia. Las etiquetas se repelen y conectan a sus puntos. El dendrograma corresponde a esta solución, que puede diferir de los grupos de Louvain de la red.','7. **Mapa temático.** `thematicMap` calcula centralidad y densidad. Un cuadrante de baja centralidad/densidad no distingue por sí solo un tema emergente de uno en declive.','8. **Tres campos.** `threeFieldsPlot` calcula relaciones keyword–país y país–autor por coaparición documental, con conteo completo; las sumas no son documentos únicos que fluyen por tres etapas. Los países son los identificables en las afiliaciones aportadas.','9. **Acoplamiento.** `biblioNetwork(analysis="coupling",network="references")` usa únicamente documentos con CR. Se corrigen los separadores de autores internos a referencias de Scopus; los fragmentos bibliográficos inválidos se excluyen y auditan. No se enriquecen referencias con fuentes externas. Variantes textuales de una misma referencia pueden quedar separadas.','10. **Cribado y chaining.** Sin decisiones de inclusión/exclusión y semillas no se puede presentar esto como corpus final de la RSL ni como un rastreo completo hacia adelante/atrás. La base aquí es exactamente la colección suministrada.','','## Documentación de la biblioteca','','- [Bibliometrix: importación](https://bibliometrix.org/vignettes/Data-Importing-and-Converting.html)','- [Manual oficial de bibliometrix](https://stat.ethz.ch/CRAN/web/packages/bibliometrix/refman/bibliometrix.html)','- [Código de threeFieldsPlot](https://github.com/massimoaria/bibliometrix/blob/master/R/threeFieldsPlot.R)')
writeLines(md,'resultados/LEEME_RESULTADOS.md',useBytes=TRUE)
cat('Entrega final:',length(figs),'figuras; PDF de',pdftools::pdf_info('resultados/Atlas_bibliometrico_Cadena_P.pdf')$pages,'paginas\n')
