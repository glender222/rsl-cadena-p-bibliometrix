options(stringsAsFactors=FALSE, timeout=600)
.libPaths(c(path.expand('~/.local/share/cadena-p/R-library'), path.expand('~/.local/share/cadena-p/system/usr/lib/R/site-library'), path.expand('~/R/library'), .libPaths()))
for (so in c('libamd.so.3','libglpk.so.40')) {
  local_so <- path.expand(paste0('~/.local/share/cadena-p/system/usr/lib/x86_64-linux-gnu/',so))
  if(file.exists(local_so)) try(dyn.load(local_so,local=FALSE),silent=TRUE)
}
suppressPackageStartupMessages(library(bibliometrix))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(igraph))
suppressPackageStartupMessages(library(ggrepel))
set.seed(20261101)
for(d in c('graficos','tablas','auditoria','objetos','interactivos')) dir.create(file.path('resultados',d),recursive=TRUE,showWarnings=FALSE)
csv <- function(x,name) write.csv(x,file.path('resultados', 'tablas',paste0(name,'.csv')),row.names=FALSE,na='',fileEncoding='UTF-8')
clean <- function(x) {x<-as.character(x);x[is.na(x)|x%in%c('NA','N/A','[No abstract available]','[No keywords available]')]<-''; trimws(gsub('[[:space:]]+',' ',x))}
present <- function(x) !is.na(x)&nzchar(trimws(as.character(x)))
splitv <- function(x) unique(trimws(unlist(strsplit(paste(x[present(x)],collapse=';'),';',fixed=TRUE))))
norm_kw <- function(x) vapply(x,function(z) paste(sort(unique(tolower(clean(splitv(z))))),collapse=';'),character(1))
canon_au <- function(x,style) vapply(x,function(z) {
  a<-splitv(z); a<-a[nzchar(a)]
  if(style=='scopus') a<-vapply(a,function(v){p<-strsplit(v,' ')[[1]]; if(length(p)<2) return(toupper(gsub('[.,]','',v))); paste(toupper(paste(head(p,-1),collapse=' ')),toupper(gsub('[^A-Za-z]','',tail(p,1))))},character(1))
  if(style=='ieee') a<-vapply(a,function(v){p<-strsplit(v,' ')[[1]]; k<-grepl('^[A-Za-z]\\.?$',p); if(any(!k)&&any(k)) paste(toupper(paste(p[!k],collapse=' ')),toupper(paste(gsub('\\.','',p[k]),collapse=''))) else toupper(gsub('[.,]','',v))},character(1))
  paste(unique(a),collapse=';')
},character(1))
palette_p <- c('#2596BE','#DE6367','#39A875','#AF75B5','#D7A630','#3BB7BF','#D77741','#6987CB')
place_network_labels <- function(nodes,size=4.1) {
  # Physical text rectangles; labels move, the graph's node coordinates do not.
  ragg::agg_png(tempfile(fileext='.png'),width=16,height=11,units='in',res=72)
  grid::grid.newpage()
  gp<-grid::gpar(fontsize=size*72.27/25.4,fontfamily='DejaVu Sans',lineheight=1.2)
  nodes$label_w<-vapply(nodes$etiqueta,function(s)grid::convertWidth(grid::grobWidth(grid::textGrob(s,gp=gp)),'in',valueOnly=TRUE),numeric(1))/15*2.84+.025
  nodes$label_h<-vapply(nodes$etiqueta,function(s)grid::convertHeight(grid::grobHeight(grid::textGrob(s,gp=gp)),'in',valueOnly=TRUE),numeric(1))/8*2.34*1.3+.025
  dev.off()
  fr<-sqrt(nodes$frecuencia);diam<-if(diff(range(fr))>0)4+16*(fr-min(fr))/diff(range(fr))else rep(10,length(fr))
  rx<-diam/25.4/2/15*2.84+.005;ry<-diam/25.4/2/8*2.34+.005
  nodes$label_x<-nodes$label_y<-NA_real_;placed<-integer()
  ang<-seq(0,100*pi,length.out=22000);rad<-seq(0,1.6,length.out=22000)
  for(i in order(-nodes$frecuencia,nodes$nombre)) {
    x<-nodes$x[i]+rad*cos(ang);y<-nodes$y[i]+rad*sin(ang)*1.3
    w<-nodes$label_w[i];h<-nodes$label_h[i]
    available<-x-w/2> -1.38 & x+w/2<1.38 & y-h/2> -1.12 & y+h/2<1.12
    for(j in placed)available<-available & !(abs(x-nodes$label_x[j])<(w+nodes$label_w[j])/2 & abs(y-nodes$label_y[j])<(h+nodes$label_h[j])/2)
    clear<-available
    for(j in seq_len(nrow(nodes)))clear<-clear & !(abs(x-nodes$x[j])<w/2+rx[j] & abs(y-nodes$y[j])<h/2+ry[j])
    k<-which(clear)[1];if(is.na(k))k<-which(available)[1]
    if(is.na(k))stop('No cabe la etiqueta de red: ',nodes$etiqueta[i])
    nodes$label_x[i]<-x[k];nodes$label_y[i]<-y[k];placed<-c(placed,i)
  }
  nodes
}
theme_p <- function(base=14) theme_minimal(base_size=base,base_family='DejaVu Sans') + theme(plot.title=element_text(face='bold',size=21,color='#192B3A',margin=margin(b=10)),plot.subtitle=element_text(size=12,color='#526574',lineheight=1.3,margin=margin(b=18)),plot.caption=element_text(size=10,color='#647581',hjust=0,margin=margin(t=16)),panel.grid.minor=element_blank(),panel.grid.major=element_line(color='#E9EEF1',linewidth=.3),plot.margin=margin(24,30,20,25),legend.position='bottom',legend.title=element_text(face='bold'),axis.title=element_text(color='#34495A'),axis.text=element_text(color='#34495A'))
save_plot <- function(p,id,w=14,h=10){
  force(p)
  ggsave(file.path('resultados/graficos',paste0(id,'.png')),p,width=w,height=h,dpi=300,bg='white',device=ragg::agg_png,limitsize=FALSE)
  ggsave(file.path('resultados/graficos',paste0(id,'.pdf')),p,width=w,height=h,device=cairo_pdf,bg='white',limitsize=FALSE)
  ggsave(file.path('resultados/graficos',paste0(id,'.svg')),p,width=w,height=h,device=svglite::svglite,bg='white',limitsize=FALSE)
}
