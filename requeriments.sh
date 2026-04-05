#!/bin/sh
# requeriments.sh
# No modelo multi-conta, servidor/URL/TMP sao injetados pelo play.sh
# via variaveis de ambiente (TWM_SRV, TWM_URL, TWM_ACC_DIR, etc)
# Este arquivo existe apenas para compatibilidade com modulos que chamam requer_func()

requer_func() {
    # No-op: variaveis ja definidas pelo orquestrador (play.sh)
    : 
}

random_ua() {
    if [ -f "$TMP/userAgent.txt" ]; then
        total=`wc -l < "$TMP/userAgent.txt"`
        n=`awk -v max="$total" 'BEGIN{srand(); print int(rand()*max)+1}'`
        vUserAgent=`sed -n "${n}p" "$TMP/userAgent.txt"`
        export vUserAgent
    fi
}
