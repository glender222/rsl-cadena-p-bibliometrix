source('scripts/00_config.R')
M<-readRDS('resultados/objetos/corpus_bibliometrix.rds')
T<-M[present(M$DE)&present(M$AU_CO)&present(M$AU),,drop=FALSE]
T$COUNTRY<-T$AU_CO
cat('Three Fields Plot:',nrow(T),'documentos completos\n')
native<-threeFieldsPlot(T,fields=c('DE','COUNTRY','AU'),n=c(12,10,16))
pb<-plotly::plotly_build(native)
s<-pb$x$data[[1]]
# Native links are pairwise co-presence counts, not flows of unique people/documents.
labels<-as.character(s$node$label);xnative<-as.numeric(s$node$x)
lev<-match(xnative,sort(unique(xnative)))
ed<-data.frame(from=as.integer(s$link$source)+1L,to=as.integer(s$link$target)+1L,weight=as.numeric(s$link$value))
node<-data.frame(id=seq_along(labels),label=labels,level=lev,x=c(.08,.5,.92)[lev])
node$incoming<-vapply(node$id,function(i)sum(ed$weight[ed$to==i]),numeric(1));node$outgoing<-vapply(node$id,function(i)sum(ed$weight[ed$from==i]),numeric(1));node$value<-pmax(node$incoming,node$outgoing)
gap<-.013
scale_flow<-min(vapply(split(node,node$level),function(z)(.88-gap*(nrow(z)-1))/sum(z$value),numeric(1)))
node$y0<-node$y1<-0
for(l in 1:3){ii<-which(node$level==l);ii<-ii[order(-node$value[ii],node$label[ii])];total<-sum(node$value[ii])*scale_flow+(length(ii)-1)*gap;cursor<-.5+total/2
 for(i in ii){node$y1[i]<-cursor;node$y0[i]<-cursor-node$value[i]*scale_flow;cursor<-node$y0[i]-gap}}
node$color<-palette_p[(ave(node$id,node$level,FUN=seq_along)-1)%%length(palette_p)+1]
# Position links within each node; widths retain the native bibliometrix values.
source_cursor<-target_cursor<-node$y1
ed<-ed[order(node$level[ed$from],-node$y1[ed$from],-node$y1[ed$to]),]
polys<-list()
bezier<-function(a,b,t)(1-t)^3*a+3*(1-t)^2*t*(a+(b-a)*.42)+3*(1-t)*t^2*(b-(b-a)*.42)+t^3*b
for(k in seq_len(nrow(ed))){i<-ed$from[k];j<-ed$to[k];h<-ed$weight[k]*scale_flow;sy1<-source_cursor[i];sy0<-sy1-h;ty1<-target_cursor[j];ty0<-ty1-h;source_cursor[i]<-sy0;target_cursor[j]<-ty0;t<-seq(0,1,length.out=65);x<-bezier(node$x[i]+.009,node$x[j]-.009,t);lo<-sy0+(ty0-sy0)*(3*t^2-2*t^3);hi<-sy1+(ty1-sy1)*(3*t^2-2*t^3);polys[[k]]<-data.frame(x=c(x,rev(x)),y=c(lo,rev(hi)),flow=k,color=node$color[i])}
poly<-do.call(rbind,polys);node$y<-(node$y0+node$y1)/2
node$textx<-ifelse(node$level==3,node$x-.019,node$x+.019);node$hjust<-ifelse(node$level==3,1,0)
# Labels are wrapped; this does not alter the terms.
node$label_wrap<-vapply(node$label,function(z)paste(strwrap(z,width=25),collapse='\n'),character(1))
p<-ggplot()+geom_polygon(data=poly,aes(x,y,group=flow,fill=I(color)),alpha=.15,color=NA)+geom_rect(data=node,aes(xmin=x-.009,xmax=x+.009,ymin=y0,ymax=y1,fill=I(color)),color='white',linewidth=.35)+geom_text(data=node,aes(textx,y,label=label_wrap,hjust=hjust),size=3.65,lineheight=.95,color='#293C4B',family='DejaVu Sans')+annotate('text',x=c(.08,.5,.92),y=1.025,label=c('PALABRAS CLAVE','PAÍSES','AUTORES'),hjust=c(0,.5,1),fontface='bold',size=4,color='#344B5A')+coord_cartesian(xlim=c(.025,.975),ylim=c(-.035,1.06),clip='off')+theme_void()+theme_p()+theme(panel.grid.major=element_blank(),panel.grid.minor=element_blank(),axis.text=element_blank(),axis.title=element_blank())+labs(title='Three-Field Plot · Palabras clave, países y autores',subtitle=sprintf('%s documentos con los tres campos · 12 palabras clave, 10 países y 16 autores como máximo',nrow(T)),caption='Enlaces calculados por bibliometrix::threeFieldsPlot · Grosor = coapariciones por pares en los documentos.\nLas sumas de enlaces pueden superar el número de artículos; no representan documentos únicos en tránsito.')
save_plot(p,'08_three_field_plot',18,12)
csv(node,'08_three_field_nodos_coordenadas');ed$source_label<-node$label[ed$from];ed$target_label<-node$label[ed$to];csv(ed,'08_three_field_enlaces')
# Interactive native object, with deliberate starting positions and generous padding.
s$node$x<-c(0,.5,1)[node$level];s$node$y<-1-node$y;s$node$pad<-16;s$node$thickness<-16;s$node$color<-node$color;s$arrangement<-'fixed';s$node$label<-node$label
pb$x$data[[1]]<-s;pb<-plotly::layout(pb,font=list(family='DejaVu Sans',size=14),width=1500,height=950,margin=list(l=80,r=80,t=70,b=70),title=list(text='Three-Field Plot · Cadena P'))
htmlwidgets::saveWidget(pb,'resultados/interactivos/08_three_field_plot.html',selfcontained=FALSE,libdir="lib")
saveRDS(native,'resultados/objetos/threeFieldsPlot_nativo.rds')
# Coupling uses cited references only; its universe is the subset with CR.
B<-M[present(M$CR),,drop=FALSE]
cat('Acoplamiento:',nrow(B),'documentos con CR\n')
WR<-cocMatrix(B,Field='CR',type='sparse',binary=TRUE,short=FALSE,sep=';')
saveRDS(WR,'resultados/objetos/documentos_referencias_normalizadas.rds')
ri<-which(as.matrix(WR)>0,arr.ind=TRUE)
csv(data.frame(DOC_ID=rownames(WR)[ri[,1]],referencia_normalizada=colnames(WR)[ri[,2]]),'documentos_referencias_normalizadas')
BC<-as.matrix(biblioNetwork(B,analysis='coupling',network='references',sep=';',short=FALSE,shortlabel=FALSE))
saveRDS(BC,'resultados/objetos/acoplamiento_documentos_completo.rds')
# Network renderer is defined in the main-figures script; load only its definition.
expr<-parse('scripts/03_graficos.R');for(e in expr)if(is.call(e)&&identical(e[[1]],as.name('<-'))&&identical(e[[2]],as.name('network_figure')))eval(e)
bc<-as.matrix(BC);diag(bc)<-0;strength<-rowSums(bc);chosen<-head(names(sort(strength[strength>0],decreasing=TRUE)),40)
lab<-setNames(vapply(seq_len(nrow(B)),function(i){author<-strsplit(ifelse(present(B$AU[i]),B$AU[i],B$DOC_ID[i]),';',fixed=TRUE)[[1]][1];paste0(author,' · ',B$PY[i],'\n',B$DOC_ID[i])},character(1)),rownames(B))
if(length(chosen)>=3){
 sub<-BC[chosen,chosen,drop=FALSE]
 bcplot<-network_figure(sub,'12_acoplamiento_bibliografico','Acoplamiento bibliográfico de documentos',sprintf('%s documentos con referencias · Se muestran hasta 40 con mayor fuerza total de acoplamiento',nrow(B)),unit='Referencias citadas',n=40,minfreq=1,minedge=2,frequency=diag(sub),labels=lab)
}
csv(data.frame(DOC_ID=rownames(BC),referencias=as.numeric(diag(BC)),fuerza_total=as.numeric(strength)),'acoplamiento_indicadores')
cat('Flujos y acoplamiento finalizados\n')
