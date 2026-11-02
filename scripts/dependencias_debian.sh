#!/usr/bin/env bash
# Debian 13: dependencias locales, sin sudo y sin cambios de paquetes del sistema.
set -euo pipefail
cache="$HOME/.local/share/cadena-p"
mkdir -p "$cache/debs" "$cache/system" "$cache/R-library"
cd "$cache/debs"
apt-get download r-cran-curl r-cran-openssl r-cran-fs r-cran-sass r-cran-qpdf r-cran-pdftools r-cran-png r-cran-igraph r-cran-httpuv r-cran-ragg libglpk40 libamd3 libcurl4-openssl-dev libssl-dev libuv1-dev libpoppler-cpp-dev libpoppler-dev
for pkg in *.deb; do dpkg-deb -x "$pkg" "$cache/system"; done
# Relocate development metadata; analysis links shared libraries, not static copies.
for pc in "$cache/system/usr/lib/x86_64-linux-gnu/pkgconfig/"*.pc; do
  sed -i "s|=/usr|=$cache/system/usr|g; s/^Requires.private:.*/Requires.private:/" "$pc"
done
for lib in libcurl.so.4 libssl.so.3 libcrypto.so.3 libuv.so.1 libpoppler-cpp.so.2; do
  if [ -e "/usr/lib/x86_64-linux-gnu/$lib" ]; then ln -sf "/usr/lib/x86_64-linux-gnu/$lib" "$cache/system/usr/lib/x86_64-linux-gnu/$lib"; fi
done
ln -sf /usr/lib/x86_64-linux-gnu/libcurl.so.4 "$cache/system/usr/lib/x86_64-linux-gnu/libcurl.so"
sed -i 's/ -lcurl / -lcurl -lssl -lcrypto /' "$cache/system/usr/lib/x86_64-linux-gnu/pkgconfig/libcurl.pc"
