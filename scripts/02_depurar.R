source('scripts/00_config.R')
raw<-readRDS('resultados/objetos/importado_preliminar.rds')
raw$DI<-tolower(gsub('^(https?://(dx\\.)?doi\\.org/|doi:[[:space:]]*)','',clean(raw$DI)))
raw$TITLE_KEY<-gsub('[^a-z0-9]','',tolower(iconv(raw$TI,to='ASCII//TRANSLIT')))
raw$TITLE_KEY[is.na(raw$TITLE_KEY)]<-''
# Deterministic components: exact DOI, then exact normalized title if no conflicting DOI.
parent<-seq_len(nrow(raw));root<-function(i){while(parent[i]!=i)i<-parent[i];i}
unite<-function(i,j){a<-root(i);b<-root(j);if(a!=b)parent[b]<<-a}
for(v in unique(raw$DI[present(raw$DI)])){ii<-which(raw$DI==v);if(length(ii)>1)for(j in ii[-1])unite(ii[1],j)}
conflict_titles<-list()
for(v in unique(raw$TITLE_KEY[nchar(raw$TITLE_KEY)>15])){
 ii<-which(raw$TITLE_KEY==v); ds<-unique(raw$DI[ii][present(raw$DI[ii])])
 if(length(ds)<=1&&length(ii)>1)for(j in ii[-1])unite(ii[1],j)
 if(length(ds)>1)conflict_titles[[v]]<-raw[ii,c('TI','DI','DB','RAW_FILE','RAW_ROW')]
}
raw$GROUP<-vapply(seq_len(nrow(raw)),root,integer(1))
priority<-match(raw$DB,c('Scopus','WoS','IEEE','Springer'))
groups<-split(seq_len(nrow(raw)),factor(raw$GROUP,levels=unique(raw$GROUP)))
union_fields<-c('DE','ID')
scalar_fields<-c('TI','AU','PY','SO','DI','AB','C1','CR','TC','DT','UT')
merged<-list();lineage<-list();conflicts<-list()
for(k in seq_along(groups)){
 ii<-groups[[k]];ii<-ii[order(priority[ii],-nchar(raw$AB[ii]))]
 z<-raw[ii[1],];z$DOC_ID<-sprintf('P%04d',k)
 for(f in scalar_fields){avail<-ii[present(raw[[f]][ii])];z[[f]]<-if(length(avail)) raw[[f]][avail[1]] else ''; if(length(unique(raw[[f]][avail]))>1&&f%in%c('PY','DI','TC'))conflicts[[length(conflicts)+1]]<-data.frame(DOC_ID=z$DOC_ID,campo=f,base=raw$DB[avail],valor=raw[[f]][avail])}
 for(f in union_fields)z[[f]]<-norm_kw(paste(raw[[f]][ii],collapse=';'))
 z$BASES<-paste(unique(raw$DB[ii]),collapse=';'); z$N_EXPORTS<-length(ii)
 # All country extraction stays within supplied affiliations; no web enrichment.
 z$C1_ALL<-paste(unique(raw$C1[ii][present(raw$C1[ii])]),collapse=';')
 z$AU_SOURCE<-if(any(present(raw$AU[ii])))raw$DB[ii[which(present(raw$AU[ii]))[1]]]else ''
 z$CR_SOURCE<-if(any(present(raw$CR[ii])))raw$DB[ii[which(present(raw$CR[ii]))[1]]]else ''
 merged[[k]]<-z
 lineage[[k]]<-data.frame(DOC_ID=z$DOC_ID,base=raw$DB[ii],archivo=raw$RAW_FILE[ii],fila=raw$RAW_ROW[ii],DI=raw$DI[ii],TI=raw$TI[ii])
}
M<-do.call(rbind,merged);rownames(M)<-NULL
M$PY<-suppressWarnings(as.integer(M$PY));M$TC<-suppressWarnings(as.numeric(M$TC))
M$DE<-norm_kw(M$DE);M$ID<-norm_kw(M$ID)
M$AU<-toupper(M$AU);M$DB<-toupper(M$DB)
M$CR<-toupper(M$CR)
M$JI<-M$J9<-M$SO;M$DT[!present(M$DT)]<-NA_character_
# SR is unique and independent of author homonyms.
M$SR<-M$SR_FULL<-M$DOC_ID;rownames(M)<-M$SR
for(f in c('AU','DE','ID','AB','C1','CR','DI','UT'))M[[f]][!present(M[[f]])]<-NA_character_
# Bibliometrix country parser against its built-in vocabulary. Preserve original affiliations.
C<-M;C$DB<-'SCOPUS';C$C1<-toupper(C$C1_ALL);C$C1[!present(C$C1)]<-NA_character_
C<-metaTagExtraction(C,Field='AU_CO',sep=';')
M$AU_CO<-vapply(C$AU_CO,function(z)if(present(z))paste(unique(splitv(z)),collapse=';')else NA_character_,character(1))
M$AU_CO[M$AU_CO%in%c('NA','NOTREPORTED','NOT REPORTED','')]<-NA_character_
M$KW_Merged<-vapply(seq_len(nrow(M)),function(i)norm_kw(paste(c(M$DE[i],M$ID[i])[present(c(M$DE[i],M$ID[i]))],collapse=';')),character(1))
M$KW_Merged[!present(M$KW_Merged)]<-NA_character_
lin<-do.call(rbind,lineage)
csv(lin,'trazabilidad_registros');csv(M,'corpus_depurado');csv(lin[duplicated(lin$DOC_ID)|duplicated(lin$DOC_ID,fromLast=TRUE),],'duplicados_consolidados')
if(length(conflicts))csv(do.call(rbind,conflicts),'conflictos_metadatos')
if(length(conflict_titles))csv(do.call(rbind,conflict_titles),'titulos_iguales_doi_distinto_revisar')
fields<-c('TI','AU','PY','DE','ID','AB','C1','AU_CO','CR','DI','TC')
coverage<-data.frame(campo=fields,registros=vapply(fields,function(f)sum(present(M[[f]])),integer(1)),total=nrow(M))
coverage$porcentaje<-round(100*coverage$registros/coverage$total,1);csv(coverage,'cobertura_campos')
csv(do.call(rbind,lapply(unique(raw$DB),function(db){d<-raw[raw$DB==db,];data.frame(base=db,registros=nrow(d),titulos=sum(present(d$TI)),autores=sum(present(d$AU)),keywords_autor=sum(present(d$DE)),referencias=sum(present(d$CR)))})),'cobertura_por_base')
saveRDS(M,'resultados/objetos/corpus_bibliometrix.rds')
stopifnot(nrow(M)==length(unique(lin$DOC_ID)),nrow(lin)==nrow(raw),!anyDuplicated(M$DI[present(M$DI)]),sum(vapply(groups,length,integer(1)))==nrow(raw),all(present(M$TI)))
cat('TOTAL BRUTO',nrow(raw),'UNICO',nrow(M),'DUPLICADOS',nrow(raw)-nrow(M),'\n');print(coverage)
