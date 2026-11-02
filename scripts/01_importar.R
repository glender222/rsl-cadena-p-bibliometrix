source('scripts/00_config.R')
files<-list.files('P',recursive=TRUE,full.names=TRUE)
manifest<-data.frame(archivo=files,bytes=file.info(files)$size,md5=unname(tools::md5sum(files)))
write.csv(manifest,'resultados/auditoria/archivos_originales.csv',row.names=FALSE)
rows<-list(); raw_objects<-list()
for(f in files){
 db<-if(grepl('/scopus/',f)) 'Scopus' else if(grepl('/WOS/',f)) 'WoS' else if(grepl('/IEEE/',f)) 'IEEE' else 'Springer'
 d<-if(db=='WoS') as.data.frame(readxl::read_xls(f)) else read.csv(f,check.names=FALSE,fileEncoding=if(db=='Scopus') 'UTF-8-BOM' else 'UTF-8')
 raw_objects[[f]]<-d
 cat(db,basename(f),nrow(d),'registros\n')
 if(db=='WoS'){print(names(d));print(d[1,intersect(names(d),c('Authors','Author Full Names','Article Title','Cited References'))])}
 pick<-function(n){if(n%in%names(d)) clean(d[[n]]) else rep('',nrow(d))}
 z<-data.frame(TI='',AU='',PY='',SO='',DI='',DE='',ID='',AB='',C1='',CR='',TC='',DT='',UT='',DB=db,RAW_FILE=f,RAW_ROW=seq_len(nrow(d)),AU_RAW='',stringsAsFactors=FALSE)
 if(db=='Scopus'){
  native<-convert2df(f,dbsource='scopus',format='csv',remove.duplicates=FALSE)
  saveRDS(native,'resultados/objetos/scopus_importacion_nativa.rds')
  z$TI<-pick('Title');z$AU_RAW<-pick('Authors');z$AU<-canon_au(z$AU_RAW,'scopus');z$PY<-pick('Year');z$SO<-pick('Source title');z$DI<-pick('DOI');z$DE<-pick('Author Keywords');z$ID<-pick('Index Keywords');z$AB<-pick('Abstract');z$C1<-pick('Affiliations');z$TC<-pick('Cited by');z$DT<-pick('Document Type');z$UT<-pick('EID')
  # Export Scopus 2026: semicolons also separate authors INSIDE each reference.
  # Split only after a closing reference year, retaining its authors as commas.
  rawcr<-pick('References')
  z$CR<-vapply(rawcr,function(s){r<-unlist(strsplit(s,'(?<=\\([12][0-9]{3}\\));[[:space:]]+',perl=TRUE));r<-gsub(';',',',r,fixed=TRUE);paste(r[nzchar(r)],collapse=';')},character(1))
 } else if(db=='IEEE'){
  z$TI<-pick('Document Title');z$AU_RAW<-pick('Authors');z$AU<-canon_au(z$AU_RAW,'ieee');z$PY<-pick('Publication Year');z$SO<-pick('Publication Title');z$DI<-pick('DOI');z$DE<-pick('Author Keywords');z$ID<-pick('IEEE Terms');z$AB<-pick('Abstract');z$C1<-pick('Author Affiliations');z$TC<-pick('Article Citation Count');z$DT<-pick('Document Identifier')
 } else if(db=='Springer'){
  z$TI<-pick('Item Title');z$AU_RAW<-pick('Authors');z$PY<-pick('Publication Year');z$SO<-pick('Publication Title');z$DI<-pick('Item DOI');z$DT<-pick('Content Type')
  # Names concatenated without delimiters: no speculative author splitting.
  z$TI<-gsub('&#xa0;',' ',z$TI,fixed=TRUE);z$TI<-gsub('&amp;','&',z$TI,fixed=TRUE)
 } else {
  z$TI<-pick('Article Title');z$AU_RAW<-pick('Authors');z$AU<-toupper(gsub(',','',pick('Authors'),fixed=TRUE));z$PY<-pick('Publication Year');z$SO<-pick('Source Title');z$DI<-pick('DOI');z$DE<-pick('Author Keywords');z$ID<-pick('Keywords Plus');z$AB<-pick('Abstract');z$C1<-pick('Addresses');z$CR<-pick('Cited References');z$TC<-pick('Times Cited, WoS Core');z$DT<-pick('Document Type');z$UT<-pick('UT (Unique WOS ID)')
 }
 rows[[f]]<-z
}
raw<-do.call(rbind,rows);rownames(raw)<-NULL
saveRDS(raw_objects,'resultados/objetos/exports_originales.rds')
saveRDS(raw,'resultados/objetos/registros_antes_deduplicar.rds')
csv(data.frame(archivo=names(rows),registros=vapply(rows,nrow,integer(1))),'recuento_exports')
# Remove year-only/empty reference fragments and retain an exclusion audit.
bad_refs<-list()
for(i in seq_len(nrow(raw))){
  rr<-strsplit(raw$CR[i],";",fixed=TRUE)[[1]]; rr<-trimws(rr); good<-nchar(rr)>=20 & grepl("[[:alpha:]]",rr)
  if(any(!good & nzchar(rr)))bad_refs[[length(bad_refs)+1]]<-data.frame(archivo=raw$RAW_FILE[i],fila=raw$RAW_ROW[i],fragmento=rr[!good & nzchar(rr)])
  raw$CR[i]<-paste(rr[good],collapse=";")
}
if(length(bad_refs))csv(do.call(rbind,bad_refs),"referencias_fragmentos_excluidos")
saveRDS(raw,"resultados/objetos/registros_antes_deduplicar.rds")
# Inspect input schema before final deduplication.
saveRDS(raw,'resultados/objetos/importado_preliminar.rds')
