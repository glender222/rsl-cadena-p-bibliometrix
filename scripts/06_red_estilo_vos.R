# Red con composición visual similar a VOSviewer, calculada en R/bibliometrix.
# No se añaden términos, enlaces ni registros a la colección.
source('scripts/00_config.R')
M<-readRDS('resultados/objetos/corpus_bibliometrix.rds')
field<-commandArgs(trailingOnly=TRUE)[1]
if(is.na(field))field<-'KW_Merged'
stopifnot(field%in%c('DE','KW_Merged'))
field_label<-if(field=='DE')'Palabras clave de autor'else'Palabras clave de autor + términos de indexación (KW_Merged)'
id<-if(field=='DE')'13_red_coocurrencia_estilo_VOS'else'14_red_coocurrencia_KW_Merged_estilo_VOS'
tag<-if(field=='DE')'13_red_estilo_vos'else'14_red_estilo_vos_KW_Merged'
K<-M[present(M[[field]]),,drop=FALSE]
W<-as.matrix(cocMatrix(K,Field=field,type='matrix',binary=TRUE,sep=';'))
f<-sort(colSums(W),decreasing=TRUE)
selected<-head(names(f[f>=2 & names(f)!='NA']),65)
C<-as.matrix(biblioNetwork(K,analysis='co-occurrences',network=if(field=='DE')'author_keywords'else'all_keywords',sep=';'))
C<-C[selected,selected,drop=FALSE]
set.seed(20261102)
native<-networkPlot(C,normalize='association',type='fruchterman',cluster='louvain',
                    community.repulsion=.2,label=TRUE,labelsize=1.1,label.cex=TRUE,
                    size=18,size.cex=TRUE,curved=TRUE,weighted=TRUE,
                    remove.isolates=TRUE,alpha=.6,seed=20261102,verbose=FALSE)
saveRDS(native,paste0('resultados/objetos/',tag,'_bibliometrix_nativa.rds'))
g<-native$graph
nodes<-data.frame(termino=V(g)$name,documentos=as.numeric(f[V(g)$name]),campo=field)
mem<-native$cluster_res$cluster[match(nodes$termino,native$cluster_res$vertex)]
# Numbering only: largest cluster first. Membership is not modified.
cl_order<-names(sort(tapply(nodes$documentos,mem,sum),decreasing=TRUE))
nodes$cluster<-factor(match(as.character(mem),cl_order))
xy<-native$layout
xy<-sweep(xy,2,apply(xy,2,median),'-')
r<-sqrt(rowSums(xy^2));denom<-max(r)
# Radial compression is a display choice; edges and weights remain identical.
xy<-xy/pmax(r,1e-8)*sqrt(r/denom)*.90
nodes$x_native<-native$layout[,1];nodes$y_native<-native$layout[,2]
nodes$x_initial<-xy[,1];nodes$y_initial<-xy[,2]
fs<-sqrt(nodes$documentos)
nodes$label_mm<-3.3+4*(fs-min(fs))/diff(range(fs))
# Pack centered labels, moving the displayed node with its label. No leader lines.
ragg::agg_png(tempfile(fileext='.png'),width=14.5,height=11,units='in',res=72)
grid::grid.newpage()
nodes$label_w<-nodes$label_h<-0
for(i in seq_len(nrow(nodes))){
 gp<-grid::gpar(fontfamily='DejaVu Sans',fontsize=nodes$label_mm[i]*72.27/25.4)
 tg<-grid::textGrob(nodes$termino[i],gp=gp)
 nodes$label_w[i]<-grid::convertWidth(grid::grobWidth(tg),'in',valueOnly=TRUE)/12*2.6+.024
 nodes$label_h[i]<-grid::convertHeight(grid::grobHeight(tg),'in',valueOnly=TRUE)/10.4*2.3*1.2+.020
}
dev.off()
nodes$x<-nodes$y<-NA_real_
angle<-seq(0,170*pi,length.out=35000);radius<-seq(0,2.8,length.out=35000)
placed<-integer()
for(i in order(-nodes$documentos,nodes$termino)){
 x<-nodes$x_initial[i]+radius*cos(angle);y<-nodes$y_initial[i]+radius*sin(angle)
 w<-nodes$label_w[i];h<-nodes$label_h[i]
 ok<-x-w/2> -1.24 & x+w/2<1.24 & y-h/2> -1.065 & y+h/2<1.065 & (x/1.12)^2+(y/1.02)^2<1
 for(j in placed)ok<-ok & !(abs(x-nodes$x[j])<(w+nodes$label_w[j])/2 & abs(y-nodes$y[j])<(h+nodes$label_h[j])/2)
 z<-which(ok)[1]
 if(is.na(z))stop('No cabe la etiqueta: ',nodes$termino[i])
 nodes$x[i]<-x[z];nodes$y[i]<-y[z];placed<-c(placed,i)
}
# Validate all centered text rectangles, then recount each link from the documents.
for(i in seq_len(nrow(nodes)-1))for(j in (i+1):nrow(nodes)){
 stopifnot(!(abs(nodes$x[i]-nodes$x[j])<(nodes$label_w[i]+nodes$label_w[j])/2 & abs(nodes$y[i]-nodes$y[j])<(nodes$label_h[i]+nodes$label_h[j])/2))
}
edges<-as_data_frame(g,what='edges')
for(i in seq_len(nrow(edges))){
 expected<-sum(W[,edges$from[i]]>0 & W[,edges$to[i]]>0)
 stopifnot(edges$weight[i]==expected)
}
vcols<-c('#2F8FC4','#E94E50','#35A650','#AB68B8','#A4B83C','#35B6BC','#E79530','#A87964')
stopifnot(nlevels(nodes$cluster)<=length(vcols))
colors<-setNames(vcols[seq_len(nlevels(nodes$cluster))],levels(nodes$cluster))
edges$x<-nodes$x[match(edges$from,nodes$termino)];edges$y<-nodes$y[match(edges$from,nodes$termino)]
edges$xend<-nodes$x[match(edges$to,nodes$termino)];edges$yend<-nodes$y[match(edges$to,nodes$termino)]
a<-as.character(nodes$cluster[match(edges$from,nodes$termino)])
b<-as.character(nodes$cluster[match(edges$to,nodes$termino)])
edges$color<-vapply(seq_len(nrow(edges)),function(i){u<-col2rgb(colors[a[i]]);v<-col2rgb(colors[b[i]]);rgb((u[1]+v[1])/510,(u[2]+v[2])/510,(u[3]+v[3])/510)},character(1))
p<-ggplot()+
 geom_curve(data=edges,aes(x,y,xend=xend,yend=yend,color=I(color),linewidth=weight),curvature=.12,ncp=7,alpha=.23,show.legend=FALSE)+
 scale_linewidth_continuous(range=c(.18,1.05),guide='none')+
 geom_point(data=nodes,aes(x,y,size=documentos,fill=cluster),shape=21,color='transparent',stroke=0,alpha=.94)+
 scale_size_area(max_size=18,guide='none')+
 geom_text(data=nodes,aes(x,y,label=termino,size=I(label_mm)),family='DejaVu Sans',color='#20252A',show.legend=FALSE)+
 scale_fill_manual(values=colors,labels=paste('Clúster',levels(nodes$cluster)),name=NULL)+
 guides(fill=guide_legend(override.aes=list(size=5.2,alpha=1,color='transparent')))+
 coord_cartesian(xlim=range(c(nodes$x-nodes$label_w/2,nodes$x+nodes$label_w/2))+c(-.045,.045),ylim=range(c(nodes$y-nodes$label_h/2,nodes$y+nodes$label_h/2))+c(-.05,.05),clip='off')+
 theme_void(base_family='DejaVu Sans')+
 theme(plot.background=element_rect(fill='white',color=NA),panel.background=element_rect(fill='white',color=NA),
       legend.position='right',legend.justification='bottom',legend.text=element_text(size=12,color='#20252A'),
       legend.key.height=grid::unit(.28,'in'),legend.margin=margin(0,4,18,0),
       plot.margin=margin(10,8,8,12),plot.caption=element_text(size=9,color='#65737A',hjust=0,margin=margin(t=8)))+
 labs(caption=sprintf('R · bibliometrix  |  %s: %s/%s documentos\n%s términos · %s enlaces · %s clústeres · Área de nodos según frecuencia documental',field_label,nrow(K),nrow(M),nrow(nodes),nrow(edges),nlevels(nodes$cluster)))
save_plot(p,id,14.5,11)
csv(nodes,paste0(tag,'_nodos_coordenadas'));csv(edges,paste0(tag,'_enlaces'))
saveRDS(p,paste0('resultados/objetos/',tag,'_grafico.rds'))
writeLines(c('Red generada en R con bibliometrix::biblioNetwork y bibliometrix::networkPlot.',
 sprintf('%s documentos con %s, de %s documentos únicos.',nrow(K),field,nrow(M)),
 'Preselección: hasta 65 términos con frecuencia documental >=2. Se eliminan términos aislados sin enlaces.',
 'No se fusionan singular/plural ni se añaden sinónimos.',
 'Louvain ponderado: número de comunidades calculado, sin fijarlo en tres.',
 'Posición inicial: networkPlot, normalización de asociación y Fruchterman-Reingold.',
 'Ajuste visual: compresión radial y posiciones de nodos/etiquetas centradas sin intersección de rectángulos.',
 'Los desplazamientos son gráficos; no modifican coocurrencias, frecuencias, pertenencias ni métricas.',
 sprintf('Verificados por recuento documental: %s enlaces.',nrow(edges)),
 'Colores identifican comunidades; área de círculos representa frecuencia documental.',
 'No se utilizó VOSviewer. El estilo se inspira en la imagen del usuario.'),
 paste0('resultados/auditoria/',tag,'_metodo.txt'))
cat('LISTO:',nrow(nodes),'nodos;',nrow(edges),'enlaces;',nlevels(nodes$cluster),'clústeres.\n')
