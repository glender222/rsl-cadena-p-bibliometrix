#!/usr/bin/env Rscript
lib <- path.expand('~/.local/share/cadena-p/R-library')
dir.create(lib, recursive=TRUE, showWarnings=FALSE)
.libPaths(c(lib, path.expand('~/.local/share/cadena-p/system/usr/lib/R/site-library'), path.expand('~/R/library'), .libPaths()))
local_sys <- path.expand('~/.local/share/cadena-p/system/usr')
if(dir.exists(local_sys)) Sys.setenv(PKG_CONFIG_PATH=paste0(local_sys,'/lib/x86_64-linux-gnu/pkgconfig'))
if(dir.exists(local_sys)) Sys.setenv(LD_LIBRARY_PATH=paste(file.path(local_sys,"lib/x86_64-linux-gnu"),Sys.getenv("LD_LIBRARY_PATH"),sep=":"))
for(so in c('libamd.so.3','libglpk.so.40')) {
  p <- file.path(local_sys,'lib/x86_64-linux-gnu',so)
  if(file.exists(p)) try(dyn.load(p,local=FALSE),silent=TRUE)
}
options(repos=c(CRAN='https://packagemanager.posit.co/cran/__linux__/trixie/latest'), Ncpus=6, timeout=600)
needed <- c('bibliometrix','readxl','ggrepel','ggalluvial','wordcloud','svglite','ragg')
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly=TRUE)]
if(length(missing)) install.packages(missing,lib=lib)
stopifnot(all(vapply(needed, requireNamespace, logical(1), quietly=TRUE)))
cat('Paquetes listos. bibliometrix ',as.character(packageVersion('bibliometrix')),'\n')
