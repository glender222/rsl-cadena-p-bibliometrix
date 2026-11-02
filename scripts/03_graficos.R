source('scripts/00_config.R')
M<-readRDS('resultados/objetos/corpus_bibliometrix.rds')
K<-M[present(M$DE),,drop=FALSE]
A<-M[present(M$AU),,drop=FALSE]
B<-M[present(M$CR),,drop=FALSE]
caption_de<-sprintf('Cadena P · Palabras clave de autor · %s de %s documentos con este campo',nrow(K),nrow(M))
cat('biblioAnalysis\n')
Aan<-A;Aan$C1<-toupper(Aan$C1_ALL)
analysis<-biblioAnalysis(Aan,sep=';');saveRDS(analysis,'resultados/objetos/biblioAnalysis.rds')
# Keywords: each document contributes at most one occurrence per term.
CW<-cocMatrix(K,Field='DE',type='matrix',binary=TRUE,sep=';')
freq<-sort(Matrix::colSums(CW),decreasing=TRUE);freq<-freq[names(freq)!='NA'&names(freq)!='']
kw<-data.frame(termino=tolower(names(freq)),documentos=as.numeric(freq));csv(kw,'frecuencias_keywords_autor')
# Every rectangle is packed and measured in R; exported positions are editable.
wordcloud_plot<-function(kw){
 d<-head(kw[kw$documentos>=2,],65)
 # Device metrics are measured at the final physical canvas size.
 ragg::agg_png(tempfile(fileext='.png'),width=14,height=9,units='in',res=100)
 grid::grid.newpage()
 d$size<-3+12*(sqrt(d$documentos)-min(sqrt(d$documentos)))/diff(range(sqrt(d$documentos)))
 d$width<-vapply(seq_len(nrow(d)),function(i)grid::convertWidth(grid::grobWidth(grid::textGrob(d$termino[i],gp=grid::gpar(fontsize=d$size[i]*72.27/25.4,fontfamily='DejaVu Sans',fontface='bold'))),'in',valueOnly=TRUE),numeric(1))/13.2
 d$height<-(d$size/25.4*1.22)/6.2
 dev.off()
 placed<-data.frame(x=numeric(),y=numeric(),w=numeric(),h=numeric())
 for(i in seq_len(nrow(d))){
  ang<-seq(0,160*pi,length.out=45000);rad<-.0008*ang
  candidates<-cbind(.5+rad*cos(ang)*1.5,.5+rad*sin(ang))
  x<-candidates[,1];y<-candidates[,2];w<-d$width[i];h<-d$height[i]
  ok<-x-w/2>=0 & x+w/2<=1 & y-h/2>=.02 & y+h/2<=.98
  if(nrow(placed))for(j in seq_len(nrow(placed)))ok<-ok & !(abs(x-placed$x[j])<(w+placed$w[j])/2+.004 & abs(y-placed$y[j])<(h+placed$h[j])/2+.006)
  j<-which(ok)[1]
  if(is.na(j))stop('No cabe el término: ',d$termino[i])
  chosen<-candidates[j,]
  placed<-rbind(placed,data.frame(x=chosen[1],y=chosen[2],w=w,h=h))
 }
 d$x<-placed$x;d$y<-placed$y;d$color<-rep(c('#1D829D','#173B62','#2BA06D','#AF639D','#B58326','#5E72A6'),length.out=nrow(d))
 csv(d,'coordenadas_wordcloud')
 ggplot(d,aes(x,y,label=termino,size=I(size),color=I(color)))+geom_text(fontface='bold',family='DejaVu Sans')+scale_x_continuous(limits=c(0,1),expand=c(0,0))+scale_y_continuous(limits=c(0,1),expand=c(0,0))+theme_void()+theme_p()+theme(panel.grid.major=element_blank(),panel.grid.minor=element_blank(),axis.title=element_blank(),axis.text=element_blank(),axis.ticks=element_blank())+labs(title='Nube de palabras clave',subtitle=sprintf('%s términos · Tamaño según número de documentos',nrow(d)),caption=caption_de)
}
save_plot(wordcloud_plot(kw),'01_wordcloud',14,9)
# Network computations are native bibliometrix; presentation uses R graphics.
network_figure<-function(mat,id,title,subtitle,unit='Documentos',n=50,minfreq=2,minedge=1,frequency=NULL,labels=NULL){
 mat<-as.matrix(mat);mat[is.na(mat)]<-0
 if(is.null(frequency))frequency<-diag(mat)
 if(is.null(names(frequency)))names(frequency)<-rownames(mat) else frequency<-frequency[rownames(mat)]
 keep<-names(sort(frequency[frequency>=minfreq],decreasing=TRUE));keep<-head(keep,n)
 mat<-mat[keep,keep,drop=FALSE];f<-frequency[keep];diag(mat)<-0;mat[mat<minedge]<-0
 keep<-rowSums(mat)>0;mat<-mat[keep,keep,drop=FALSE];f<-f[keep]
 if(nrow(mat)<3)stop('Red insuficiente: ',id)
 gn<-graph_from_adjacency_matrix(mat,mode='undirected',weighted=TRUE,diag=FALSE)
 assoc<-E(gn)$weight/(f[ends(gn,E(gn))[,1]]*f[ends(gn,E(gn))[,2]])
 set.seed(20261101);cl<-cluster_louvain(gn,weights=assoc)
 mem<-membership(cl); ord<-names(sort(tapply(f,mem,sum),decreasing=TRUE));mem<-match(as.character(mem),ord)
 set.seed(20261101); xy<-layout_with_fr(gn,weights=sqrt(assoc/max(assoc)),niter=6000,grid='nogrid');xy<-norm_coords(xy,xmin=-1,xmax=1,ymin=-.85,ymax=.85)
 nodes<-data.frame(nombre=V(gn)$name,x=xy[,1],y=xy[,2],frecuencia=as.numeric(f[V(gn)$name]),cluster=factor(mem))
 nodes$etiqueta<-if(is.null(labels))tolower(nodes$nombre) else unname(labels[nodes$nombre])
 nodes<-place_network_labels(nodes)
 ed<-as_data_frame(gn,what='edges');ed$x<-nodes$x[match(ed$from,nodes$nombre)];ed$y<-nodes$y[match(ed$from,nodes$nombre)];ed$xend<-nodes$x[match(ed$to,nodes$nombre)];ed$yend<-nodes$y[match(ed$to,nodes$nombre)];ed$cluster<-nodes$cluster[match(ed$from,nodes$nombre)]
 csv(nodes,paste0(id,'_nodos'));csv(ed,paste0(id,'_enlaces'));saveRDS(list(graph=gn,clusters=cl,nodes=nodes,edges=ed),'resultados/objetos/' |> paste0(id,'.rds'))
 p<-ggplot()+geom_segment(data=ed,aes(x=x,y=y,xend=xend,yend=yend,linewidth=weight,color=cluster),alpha=.28,show.legend=FALSE)+scale_linewidth_continuous(range=c(.2,1.35))+geom_point(data=nodes,aes(x,y,size=frecuencia,fill=cluster),shape=21,color='white',stroke=.65,alpha=.92)+geom_segment(data=nodes,aes(x=x,y=y,xend=label_x,yend=label_y),color='#A3AFB7',linewidth=.22)+geom_text(data=nodes,aes(label_x,label_y,label=etiqueta),size=4.1,family='DejaVu Sans',lineheight=1.2)+scale_fill_manual(values=palette_p,name='Clúster')+scale_color_manual(values=palette_p)+scale_size_continuous(range=c(4,20),name=unit,breaks=scales::breaks_pretty(3))+guides(size=guide_legend(override.aes=list(fill='#8EA7B4',color='white')),fill=guide_legend(override.aes=list(size=4)))+coord_cartesian(xlim=c(-1.42,1.42),ylim=c(-1.17,1.17),clip='off')+theme_void()+theme_p()+theme(panel.grid.major=element_blank(),panel.grid.minor=element_blank(),axis.text=element_blank(),axis.title=element_blank())+labs(title=title,subtitle=subtitle,caption=sprintf('%s nodos · %s enlaces · %s clústeres Louvain · Posición: Fruchterman–Reingold',nrow(nodes),nrow(ed),length(unique(mem))))
 save_plot(p,id,16,11)
 list(p=p,nodes=nodes,edges=ed,graph=gn,clusters=cl)
}
cat('coocurrencia\n')
Net<-biblioNetwork(K,analysis='co-occurrences',network='author_keywords',sep=';');saveRDS(Net,'resultados/objetos/red_coocurrencia_completa.rds')
net<-network_figure(Net,'02_coocurrencia','Red de coocurrencia de palabras clave',paste0(caption_de,'\nHasta 50 términos con ≥2 documentos · Enlaces con ≥1 coocurrencia'),n=50,minfreq=2,minedge=1,frequency=setNames(as.numeric(freq),names(freq)))
# Cluster membership and keywords without inventing thematic names.
csv(net$nodes[order(net$nodes$cluster,-net$nodes$frecuencia),],'clusters_coocurrencia')
# Author collaboration; count publications, not summed edge weights.
cat('colaboracion autores\n')
CA<-cocMatrix(A,Field='AU',type='matrix',binary=TRUE,sep=';');fa<-Matrix::colSums(CA)
Nau<-biblioNetwork(A,analysis='collaboration',network='authors',sep=';');saveRDS(Nau,'resultados/objetos/red_autores_completa.rds')
au_net<-network_figure(Nau,'03_colaboracion_autores','Red de colaboración entre autores',sprintf('%s documentos con autores separables · Hasta 40 autores con ≥3 publicaciones',nrow(A)),n=40,minfreq=3,minedge=1,frequency=fa)
# Countries: extraction from supplied affiliations only, preserve multi-country counting.
cat('colaboracion paises\n')
C<-M[present(M$AU_CO),,drop=FALSE];CC<-cocMatrix(C,Field='AU_CO',type='matrix',binary=TRUE,sep=';');fc<-Matrix::colSums(CC)
# Use explicitly extracted country field to avoid silently reparsing a different C1.
NC<-Matrix::crossprod(CC)
country_net<-network_figure(NC,'04_colaboracion_paises','Red de colaboración entre países',sprintf('%s documentos con país identificable en sus afiliaciones · Enlace = coautoría internacional',nrow(C)),n=25,minfreq=2,minedge=1,frequency=fc)
# Factorial structure: native bibliometrix MCA; coordinates never adjusted for aesthetics.
cat('factorial\n')
set.seed(20261101)
cs<-conceptualStructure(K,field='DE',method='MCA',minDegree=4,clust='auto',k.max=5,stemming=FALSE,labelsize=12,documents=2,graph=FALSE)
saveRDS(cs,'resultados/objetos/estructura_conceptual_MCA.rds')
d<-cs$km.res$data.clust;d$termino<-rownames(d);d$clust<-factor(d$clust)
csv(d,'coordenadas_factoriales_MCA')
hulls<-do.call(rbind,lapply(split(d,d$clust),function(z)if(nrow(z)>=3)z[chull(z$Dim1,z$Dim2),]else z[FALSE,]))
eig<-cs$res$eigCorr
saveRDS(cs$res,'resultados/objetos/resultado_factorial.rds')
xlab<-'Dimensión 1';ylab<-'Dimensión 2'
if(!is.null(eig$perc)){xlab<-sprintf('Dimensión 1 (%.1f%% de inercia corregida)',eig$perc[1]);ylab<-sprintf('Dimensión 2 (%.1f%% de inercia corregida)',eig$perc[2])}
pfactor<-ggplot(d,aes(Dim1,Dim2,color=clust))+geom_hline(yintercept=0,linetype='dashed',color='#AAB5BD',linewidth=.4)+geom_vline(xintercept=0,linetype='dashed',color='#AAB5BD',linewidth=.4)+geom_polygon(data=hulls,aes(fill=clust,group=clust),alpha=.12,linewidth=.6,show.legend=FALSE)+geom_point(size=2.6)+geom_text_repel(aes(label=termino),seed=20261101,size=4,box.padding=.7,point.padding=.3,max.overlaps=Inf,max.time=Inf,max.iter=50000,min.segment.length=0,segment.color='#A4AFB8')+scale_color_manual(values=palette_p,name='Clúster factorial')+scale_fill_manual(values=palette_p)+scale_x_continuous(expand=expansion(mult=.18))+scale_y_continuous(expand=expansion(mult=.18))+theme_p()+labs(title='Estructura conceptual · Mapa factorial',subtitle=sprintf('Análisis de correspondencias múltiples (MCA) · %s términos presentes en ≥4 documentos',nrow(d)),x=xlab,y=ylab,caption=paste0(caption_de,'\nCoordenadas calculadas por bibliometrix; las líneas guían hacia etiquetas desplazadas.'))
save_plot(pfactor,'05_mapa_factorial_MCA',16,11)
# Hierarchical clustering from the same native factorial solution.
cat('dendrograma\n')
hc<-cs$km.res; merges<-hc$merge; y<-hc$height; xpos<-seq_along(hc$order);names(xpos)<-as.character(hc$order);xs<-numeric(nrow(merges));segments<-list()
for(i in seq_len(nrow(merges))){a<-merges[i,1];b<-merges[i,2];xa<-if(a<0)xpos[as.character(-a)]else xs[a];xb<-if(b<0)xpos[as.character(-b)]else xs[b];ya<-if(a<0)0 else y[a];yb<-if(b<0)0 else y[b];xs[i]<-mean(c(xa,xb));segments[[i]]<-data.frame(x=c(xa,xb,xa),y=c(ya,yb,y[i]),xend=c(xa,xb,xb),yend=c(y[i],y[i],y[i]))}
ds<-do.call(rbind,segments);leaf<-data.frame(x=seq_along(hc$order),y=0,termino=hc$labels[hc$order],clust=factor(hc$cluster[hc$order]))
pdend<-ggplot()+geom_segment(data=ds,aes(x=y,y=x,xend=yend,yend=xend),color='#657987',linewidth=.6)+geom_point(data=leaf,aes(x=0,y=x,color=clust),size=2.4)+geom_text(data=leaf,aes(x=-max(hc$height)*.025,y=x,label=termino,color=clust),hjust=1,size=3.8)+scale_color_manual(values=palette_p,name='Clúster factorial')+scale_x_continuous(breaks=pretty(c(0,max(hc$height))))+scale_y_continuous(breaks=NULL)+coord_cartesian(xlim=c(-max(hc$height)*.34,max(hc$height)*1.03),clip='off')+theme_p()+theme(panel.grid.major.y=element_blank())+labs(title='Agrupamiento jerárquico de palabras clave',subtitle='Enlace promedio sobre las coordenadas factoriales de bibliometrix',x='Distancia de agrupamiento',y=NULL,caption=caption_de)
save_plot(pdend,'06_clustering_dendrograma',16,11)
# Thematic map: same metrics and clusters as bibliometrix, repel labels only.
cat('mapa tematico\n')
tm<-thematicMap(K,field='DE',n=80,minfreq=15,n.labels=3,repel=TRUE,cluster='louvain',seed=20261101)
saveRDS(tm,'resultados/objetos/mapa_tematico.rds');csv(tm$clusters,'mapa_tematico_clusters');csv(tm$words,'mapa_tematico_terminos')
print(names(tm$clusters));print(tm$clusters)
# Native map is restyled without modifying coordinates or quadrant thresholds.
td<-as.data.frame(tm$clusters);td$cluster<-factor(seq_len(nrow(td)))
p_tm<-ggplot(td,aes(rcentrality,rdensity))+geom_vline(xintercept=tm$axisOrigin[1],linetype='dashed',color='#788A96',linewidth=.5)+geom_hline(yintercept=tm$axisOrigin[2],linetype='dashed',color='#788A96',linewidth=.5)+geom_point(aes(size=freq,fill=cluster,color=cluster),shape=21,alpha=.35,stroke=.8)+geom_text(aes(label=name_full),size=4.2,fontface='bold',family='DejaVu Sans',color='#263E4B',lineheight=1.2)+scale_fill_manual(values=palette_p,guide='none')+scale_color_manual(values=palette_p,guide='none')+scale_size_area(max_size=38,name='Ocurrencias de términos',breaks=scales::breaks_pretty(3))+guides(size=guide_legend(override.aes=list(fill='#AECAD4',color='#6B93A4',alpha=.6)))+annotate('text',x=c(.6,6.9,.6,6.9),y=c(7.1,7.1,.25,.25),label=c('TEMAS DE NICHO','TEMAS MOTORES','EMERGENTES O EN DECLIVE','TEMAS BÁSICOS'),hjust=c(0,1,0,1),size=3.5,color='#7A8F9C',fontface='bold')+scale_x_continuous(limits=c(.4,7.15),breaks=1:6)+scale_y_continuous(limits=c(0,7.35),breaks=1:6)+theme_p()+theme(panel.grid.major=element_blank(),axis.line=element_line(color='#6E8594',linewidth=.35))+labs(title='Mapa temático',subtitle='Palabras clave de autor · Los tres términos principales identifican cada tema',x='Centralidad (rango)',y='Densidad (rango)',caption=paste0(caption_de,'\nCentralidad, densidad y agrupamiento calculados por bibliometrix::thematicMap.'))
save_plot(p_tm,'07_mapa_tematico',15,11)
# Descriptive figures cover the full supplied collection, irrespective of keyword availability.
annual<-as.data.frame(table(M$PY));names(annual)<-c('anio','documentos');annual$anio<-as.integer(as.character(annual$anio));annual<-annual[order(annual$anio),];csv(annual,'produccion_anual')
pyear<-ggplot(annual,aes(anio,documentos))+geom_col(fill='#258DAA',width=.7)+geom_text(aes(label=documentos),vjust=-.6,size=4.5,color='#244355')+scale_x_continuous(breaks=sort(unique(c(min(annual$anio),seq(1980,max(annual$anio),by=5),max(annual$anio)))))+scale_y_continuous(expand=expansion(mult=c(0,.16)))+theme_p()+labs(title='Producción científica anual',subtitle=sprintf('%s documentos únicos de la colección exportada',nrow(M)),x='Año de publicación',y='Documentos',caption='Años según los exports originales · Los años recientes pueden estar incompletos; no se proyectaron valores.')
save_plot(pyear,'09_produccion_anual',14,8)
counts<-function(x)sort(table(splitv(x)),decreasing=TRUE)
sources<-sort(table(M$SO),decreasing=TRUE);st<-head(data.frame(fuente=names(sources),documentos=as.numeric(sources)),12);csv(data.frame(fuente=names(sources),documentos=as.numeric(sources)),'fuentes_publicacion')
st$etiqueta<-stringr::str_wrap(st$fuente,width=64)
pso<-ggplot(st,aes(documentos,reorder(etiqueta,documentos)))+geom_col(fill='#258DAA',width=.64)+geom_text(aes(label=documentos),hjust=-.25,size=4)+scale_x_continuous(expand=expansion(mult=c(0,.12)))+theme_p()+theme(panel.grid.major.y=element_blank(),axis.text.y=element_text(size=11))+labs(title='Fuentes de publicación más frecuentes',subtitle='Las 12 principales revistas, congresos y libros de la colección',x='Documentos',y=NULL,caption=sprintf('Cadena P · %s documentos únicos · Conteo por título de fuente exportado',nrow(M)))
save_plot(pso,'10_fuentes_publicacion',15,10)
# Top keyword frequencies: transparent complement to the word cloud.
top<-head(kw,20)
pkw<-ggplot(top,aes(documentos,reorder(termino,documentos)))+geom_segment(aes(x=0,xend=documentos,yend=reorder(termino,documentos)),color='#D7E8EE',linewidth=2)+geom_point(color='#258DAA',size=4)+geom_text(aes(label=documentos),hjust=-.7,size=4)+scale_x_continuous(expand=expansion(mult=c(0,.12)))+theme_p()+theme(panel.grid.major.y=element_blank())+labs(title='Palabras clave de autor más frecuentes',subtitle='20 términos principales · Un documento cuenta una vez por término',x='Documentos',y=NULL,caption=caption_de)
save_plot(pkw,'11_frecuencias_keywords',13,10)
cat('Graficos principales finalizados\n')
