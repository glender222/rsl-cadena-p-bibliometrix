#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
mkdir -p resultados/auditoria
Rscript scripts/instalar.R > resultados/auditoria/instalacion.log 2>&1
for script in scripts/01_importar.R scripts/02_depurar.R scripts/03_graficos.R scripts/04_flujos_acoplamiento.R; do
  Rscript "$script" 2>&1 | tee "resultados/auditoria/$(basename "$script" .R).log"
done
for campo in DE KW_Merged; do
  Rscript scripts/06_red_estilo_vos.R "$campo" 2>&1 | tee "resultados/auditoria/red_estilo_vos_${campo}.log"
done
Rscript scripts/07_compactar_redes.R 2>&1 | tee resultados/auditoria/07_compactar_redes.log
Rscript scripts/05_entrega.R 2>&1 | tee resultados/auditoria/05_entrega.log
