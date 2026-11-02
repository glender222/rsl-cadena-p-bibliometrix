# Ajuste de presentación sobre resultados de bibliometrix ya calculados.
# No selecciona nuevos nodos ni recalcula enlaces, pesos o comunidades.
source('scripts/00_config.R')

pack_network <- function(nodes, w, h, variable_labels=FALSE) {
  # Keep the original layout for deterministic reruns and provenance.
  if (!all(c('x_original','y_original') %in% names(nodes))) {
    nodes$x_original <- nodes$x
    nodes$y_original <- nodes$y
  }
  xy <- as.matrix(nodes[,c('x_original','y_original')])
  xy <- sweep(xy,2,apply(xy,2,median),'-')
  r <- sqrt(rowSums(xy^2))
  xy <- xy/pmax(r,1e-10) * (r/max(r))^.58 * .61
  xy[,1] <- xy[,1]*1.17
  # Bring community centres closer while keeping the within-group orientation.
  # These display coordinates are not factor scores or geographic locations.
  centres <- sapply(1:2,function(k)ave(xy[,k],nodes$cluster,FUN=mean))
  xy <- xy-.45*centres
  s <- sqrt(nodes$frecuencia)
  spread <- if(diff(range(s))>0) (s-min(s))/diff(range(s)) else rep(.5,length(s))
  nodes$label_mm <- if(variable_labels) 3.15+2.7*spread else 3.85+.45*spread
  nodes$etiqueta <- vapply(nodes$etiqueta,function(z)
    paste(vapply(strsplit(z,'\n',fixed=TRUE)[[1]],function(line)
      paste(strwrap(line,width=32),collapse='\n'),character(1)),collapse='\n'),character(1))
  # Conservative physical text bounds, in the same units as display positions.
  ragg::agg_png(tempfile(fileext='.png'),width=w,height=h,units='in',res=72)
  grid::grid.newpage()
  nodes$label_w <- nodes$label_h <- 0
  for(i in seq_len(nrow(nodes))) {
    gp <- grid::gpar(fontfamily='DejaVu Sans',fontsize=nodes$label_mm[i]*72.27/25.4,lineheight=1.05)
    tg <- grid::textGrob(nodes$etiqueta[i],gp=gp)
    nodes$label_w[i] <- grid::convertWidth(grid::grobWidth(tg),'in',valueOnly=TRUE)/(w-.9)*2.4+.018
    nodes$label_h[i] <- grid::convertHeight(grid::grobHeight(tg),'in',valueOnly=TRUE)/(h-2.3)*1.84+.022
  }
  dev.off()
  diam <- if(variable_labels) 17*sqrt(nodes$frecuencia/max(nodes$frecuencia)) else 4+13*spread
  rx <- diam/25.4/(w-.9)*2.4/2
  ry <- diam/25.4/(h-2.3)*1.84/2
  nodes$x <- nodes$y <- NA_real_
  angle <- seq(0,200*pi,length.out=60000)
  radius <- seq(0,1.9,length.out=length(angle))
  placed <- integer()
  for(i in order(-nodes$frecuencia,nodes$nombre)) {
    x <- xy[i,1]+radius*cos(angle)
    y <- xy[i,2]+radius*sin(angle)*.8
    ww <- nodes$label_w[i]; hh <- nodes$label_h[i]
    ok <- x-ww/2> -1.13 & x+ww/2<1.13 & y-hh/2> -.85 & y+hh/2<.85
    for(j in placed) {
      ok <- ok & !(abs(x-nodes$x[j])<(ww+nodes$label_w[j])/2 &
                    abs(y-nodes$y[j])<(hh+nodes$label_h[j])/2)
      ok <- ok & ((x-nodes$x[j])/(rx[i]+rx[j]+.012))^2+
                 ((y-nodes$y[j])/(ry[i]+ry[j]+.012))^2 >= 1
    }
    k <- which(ok)[1]
    if(is.na(k)) stop('No cabe la etiqueta: ',nodes$nombre[i])
    nodes$x[i] <- x[k]; nodes$y[i] <- y[k]
    placed <- c(placed,i)
  }
  nodes$label_x <- nodes$x; nodes$label_y <- nodes$y
  for(i in seq_len(nrow(nodes)-1)) for(j in (i+1):nrow(nodes))
    stopifnot(!(abs(nodes$x[i]-nodes$x[j])<(nodes$label_w[i]+nodes$label_w[j])/2 &
                abs(nodes$y[i]-nodes$y[j])<(nodes$label_h[i]+nodes$label_h[j])/2))
  nodes
}

specs <- list(
  list(id='02_coocurrencia',tag='02_coocurrencia',title='Red de coocurrencia de palabras clave',w=13,h=9),
  list(id='03_colaboracion_autores',tag='03_colaboracion_autores',title='Red de colaboración entre autores',w=12,h=8.3),
  list(id='04_colaboracion_paises',tag='04_colaboracion_paises',title='Red de colaboración entre países',w=10.5,h=7.4),
  list(id='12_acoplamiento_bibliografico',tag='12_acoplamiento_bibliografico',title='Acoplamiento bibliográfico de documentos',w=13.5,h=9.6),
  list(id='13_red_coocurrencia_estilo_VOS',tag='13_red_estilo_vos',title='Coocurrencia · Palabras clave de autor',w=13,h=9.2,vos=TRUE),
  list(id='14_red_coocurrencia_KW_Merged_estilo_VOS',tag='14_red_estilo_vos_KW_Merged',title='Coocurrencia · Palabras clave e indexación',w=13,h=9.2,vos=TRUE)
)
requested <- commandArgs(trailingOnly=TRUE)
if(length(requested)) specs <- Filter(function(s)s$id %in% requested,specs)
M <- readRDS('resultados/objetos/corpus_bibliometrix.rds')
audit <- list()
for(s in specs) {
  vos <- isTRUE(s$vos)
  nf <- if(vos) paste0(s$tag,'_nodos_coordenadas') else paste0(s$tag,'_nodos')
  nodes <- read.csv(paste0('resultados/tablas/',nf,'.csv'))
  ed <- read.csv(paste0('resultados/tablas/',s$tag,'_enlaces.csv'))
  if(vos) {
    nodes$nombre <- nodes$termino; nodes$frecuencia <- nodes$documentos
    nodes$etiqueta <- nodes$termino
  }
  nodes$cluster <- factor(nodes$cluster,levels=sort(unique(nodes$cluster)))
  before_nodes <- nodes[,c('nombre','frecuencia','cluster')]
  before_edges <- ed[,c('from','to','weight')]
  nodes <- pack_network(nodes,s$w,s$h,variable_labels=vos)
  if(s$id=='04_colaboracion_paises') {
    # Keep disconnected countries in a nearby, visibly separate component;
    # their edge must not run through a country in the principal component.
    cc <- components(graph_from_data_frame(ed[,c('from','to')],directed=FALSE,vertices=nodes$nombre))
    principal <- which.max(cc$csize)
    main <- cc$membership[nodes$nombre]==principal
    right <- max(nodes$x[main]+nodes$label_w[main]/2)
    for(k in setdiff(unique(cc$membership),principal)) {
      ii <- which(cc$membership[nodes$nombre]==k)
      nodes$x[ii] <- nodes$x[ii]+right+.10-min(nodes$x[ii]-nodes$label_w[ii]/2)
      nodes$y[ii] <- nodes$y[ii]-mean(nodes$y[ii])
      right <- max(nodes$x[ii]+nodes$label_w[ii]/2)
    }
    nodes$label_x <- nodes$x; nodes$label_y <- nodes$y
  }
  for(v in c('x','y')) {
    ed[[v]] <- nodes[[v]][match(ed$from,nodes$nombre)]
    ed[[paste0(v,'end')]] <- nodes[[v]][match(ed$to,nodes$nombre)]
  }
  ed$cluster <- nodes$cluster[match(ed$from,nodes$nombre)]
  cols <- if(vos) c('#2F8FC4','#E94E50','#35A650','#AB68B8','#A4B83C','#35B6BC','#E79530','#A87964') else palette_p
  p <- ggplot()
  if(vos) {
    a <- cols[as.integer(ed$cluster)]
    b <- cols[as.integer(nodes$cluster[match(ed$to,nodes$nombre)])]
    ed$color <- vapply(seq_len(nrow(ed)),function(i) {
      z <- (col2rgb(a[i])+col2rgb(b[i]))/2
      rgb(z[1],z[2],z[3],maxColorValue=255)
    },character(1))
    p <- p+geom_curve(data=ed,aes(x,y,xend=xend,yend=yend,color=I(color),linewidth=weight),
                     curvature=.10,ncp=7,alpha=.25,show.legend=FALSE)
  } else p <- p+geom_segment(data=ed,aes(x,y,xend=xend,yend=yend,color=cluster,linewidth=weight),alpha=.35,show.legend=FALSE)
  p <- p+scale_linewidth_continuous(range=c(.22,1.25),guide='none')+
    geom_point(data=nodes,aes(x,y,size=frecuencia,fill=cluster),shape=21,color='white',stroke=.35,alpha=.82)
  size_name <- if(s$id=='12_acoplamiento_bibliografico')'Referencias citadas'else'Documentos'
  p <- p+if(vos)scale_size_area(max_size=17,name=size_name,breaks=scales::breaks_pretty(3))else
    scale_size_continuous(range=c(4,17),name=size_name,breaks=scales::breaks_pretty(3))
  p <- p+
    geom_text(data=nodes,aes(x,y,label=etiqueta,size=I(label_mm)),family='DejaVu Sans',lineheight=1.05,color='#202D36',show.legend=FALSE)+
    scale_fill_manual(values=cols,name='Clúster')+scale_color_manual(values=cols)+
    guides(fill=guide_legend(override.aes=list(size=4.5,alpha=1),nrow=1),
           size=guide_legend(override.aes=list(fill='#8EA7B4',color='white'),nrow=1))+
    coord_cartesian(xlim=range(c(nodes$x-nodes$label_w/2,nodes$x+nodes$label_w/2))+c(-.045,.045),
                    ylim=range(c(nodes$y-nodes$label_h/2,nodes$y+nodes$label_h/2))+c(-.045,.045),clip='off')+
    theme_void(base_family='DejaVu Sans')+theme_p(12)+
    theme(panel.grid.major=element_blank(),panel.grid.minor=element_blank(),axis.title=element_blank(),axis.text=element_blank(),
          plot.title=element_text(size=19,margin=margin(b=6)),plot.subtitle=element_text(size=11,margin=margin(b=9)),
          plot.caption=element_text(size=9,margin=margin(t=8)),plot.margin=margin(15,17,13,17),
          legend.margin=margin(1,2,1,2),legend.box.spacing=grid::unit(2,'mm'),legend.key.height=grid::unit(6,'mm'))
  coverage <- if(s$id=='03_colaboracion_autores')sum(present(M$AU))else
    if(s$id=='04_colaboracion_paises')sum(present(M$AU_CO))else
    if(s$id=='12_acoplamiento_bibliografico')sum(present(M$CR))else
    if(grepl('KW_Merged',s$tag))sum(present(M$KW_Merged))else sum(present(M$DE))
  p <- p+labs(title=s$title,subtitle=sprintf('%s nodos · %s enlaces · %s clústeres · %s/%s documentos con el campo',
       nrow(nodes),nrow(ed),nlevels(nodes$cluster),coverage,nrow(M)),
       caption='R · bibliometrix | Disposición compacta; etiquetas centradas en cada nodo.\nLas distancias son de presentación; se conservan los nodos, enlaces, pesos y clústeres.')
  stopifnot(identical(before_nodes,nodes[,c('nombre','frecuencia','cluster')]),identical(before_edges,ed[,c('from','to','weight')]))
  save_plot(p,s$id,s$w,s$h)
  csv(nodes,nf); csv(ed,paste0(s$tag,'_enlaces'))
  if(s$id=='02_coocurrencia')csv(nodes[order(nodes$cluster,-nodes$frecuencia),],'clusters_coocurrencia')
  if(!vos) {
    objfile <- paste0('resultados/objetos/',s$tag,'.rds')
    obj <- readRDS(objfile); obj$nodes <- nodes; obj$edges <- ed; obj$p <- p
    saveRDS(obj,objfile)
  } else saveRDS(p,paste0('resultados/objetos/',s$tag,'_grafico.rds'))
  audit[[s$id]] <- data.frame(figura=s$id,nodos=nrow(nodes),enlaces=nrow(ed),clusters=nlevels(nodes$cluster),
                              ancho_pulgadas=s$w,alto_pulgadas=s$h,rectangulos_sin_interseccion=TRUE,
                              nodos_pesos_y_clusters_sin_cambios=TRUE)
  cat(s$id,': disposición compacta verificada.\n')
}
csv(do.call(rbind,audit),'auditoria_disposicion_compacta')
writeLines(c(
  'Presentación sobre seis redes calculadas previamente con bibliometrix.',
  'Las coordenadas originales de presentación se conservan en x_original e y_original.',
  'Compresión radial con exponente 0.58 y aproximación del 45% de los centros de las comunidades.',
  'Acomodo determinista de etiquetas y nodos juntos, con límites físicos de texto sin intersección.',
  'Los componentes desconectados de países se mantienen separados visualmente.',
  'No cambian selección de nodos, frecuencias, enlaces, pesos ni pertenencias a comunidades.',
  'MCA y mapa temático: sin cambios de coordenadas, métricas ni umbrales.',
  'Las distancias finales en las redes son de presentación, no medidas estadísticas.'),
  'resultados/auditoria/disposicion_compacta_metodo.txt')
