#!/bin/sh
# shellcheck disable=SC1091
# twm.sh - Worker de conta individual (nao interativo)
# Variaveis esperadas do orquestrador (play.sh):
#   TWM_SRV      — numero do servidor (1-13)
#   TWM_URL      — URL completa (https://furiadetitas.net)
#   TWM_USER     — nome de usuario
#   TWM_TAG      — tag do servidor (BR, EN, etc)
#   TWM_ACC_DIR  — diretorio isolado da conta (~/.twm/BR_User)
#   TWM_STATUS_FILE — arquivo de status desta conta

# TWMDIR: diretorio dos scripts
if [ -z "$TWMDIR" ]; then
    _d=`dirname "$0"`
    TWMDIR=`cd "$_d" && pwd`
    unset _d
    export TWMDIR
fi

# Valida variaveis obrigatorias
if [ -z "$TWM_SRV" ] || [ -z "$TWM_URL" ] || [ -z "$TWM_ACC_DIR" ]; then
    printf "ERRO: twm.sh deve ser chamado pelo play.sh (variaveis TWM_* ausentes)\n"
    exit 1
fi

# Define variaveis de ambiente da conta
URL="$TWM_URL"
UR="$TWM_SRV"
TMP="$TWM_ACC_DIR"
TMP_COOKIE="$TMP/cookie.txt"
export URL UR TMP TMP_COOKIE

# Fuso horario por servidor
case "$UR" in
    1)  export TZ="America/Bahia" ;;
    2)  export TZ="Europe/Berlin" ;;
    3)  export TZ="America/Cancun" ;;
    4)  export TZ="Europe/Paris" ;;
    5)  export TZ="Asia/Kolkata" ;;
    6)  export TZ="Asia/Jakarta" ;;
    7)  export TZ="Europe/Rome" ;;
    8)  export TZ="Europe/Warsaw" ;;
    9)  export TZ="Europe/Bucharest" ;;
    10) export TZ="Europe/Moscow" ;;
    11) export TZ="Europe/Belgrade" ;;
    12) export TZ="Asia/Shanghai" ;;
    13) export TZ="Europe/London" ;;
esac

mkdir -p "$TMP"

# Carrega info.sh (run_curl, fetch_page, colors, echo_t, etc)
. "$TWMDIR/info.sh"
colors

RUN=`cat "$TWMDIR/runmode_file" 2>/dev/null || echo '-boot'`

# Termux wake lock (uma vez por processo)
if [ -d /data/data/com.termux/files/usr/share/doc ]; then
    termux-wake-lock 2>/dev/null
fi

# Carrega todas as bibliotecas
cd "$TWMDIR" || exit 1
for _lib in \
    language.sh \
    flagfight.sh \
    clanid.sh \
    crono.sh \
    arena.sh \
    coliseum.sh \
    campaign.sh \
    run.sh \
    altars.sh \
    clandmg.sh \
    clanfight.sh \
    clancoliseum.sh \
    king.sh \
    undying.sh \
    trade.sh \
    career.sh \
    cave.sh \
    allies.sh \
    svproxy.sh \
    check.sh \
    league.sh \
    specialevent.sh \
    function.sh \
    update_check.sh
do
    [ -f "$TWMDIR/$_lib" ] && . "$TWMDIR/$_lib"
done
unset _lib

# Fallback translate_and_cache
type translate_and_cache > /dev/null 2>&1 || translate_and_cache() { echo "$2"; }

# language_setup agora que TMP esta definido
language_setup
load_config

# userAgent
if [ ! -f "$TMP/userAgent.txt" ] && [ -f "$TWMDIR/userAgent.txt" ]; then
    cp "$TWMDIR/userAgent.txt" "$TMP/userAgent.txt"
fi
random_ua 2>/dev/null || vUserAgent="Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36"
export vUserAgent

printf "[%s] %s — iniciando em %s\n" "$TWM_TAG" "$TWM_USER" "$URL"

# LOGIN — nao interativo: usa crit_file do diretorio da conta
login_worker() {
    cript_file="$TMP/cript_file"

    if [ ! -f "$cript_file" ]; then
        printf "[%s] %s — ERRO: cript_file ausente\n" "$TWM_TAG" "$TWM_USER"
        exit 1
    fi

    creds=`base64 -d "$cript_file" 2>/dev/null`
    luser=`echo "$creds" | sed 's/login=//;s/&pass=.*//'`
    lpass=`echo "$creds" | sed 's/.*&pass=//'`
    unset creds

    # Login 2x
    run_curl --data-urlencode "login=${luser}" \
             --data-urlencode "pass=${lpass}" \
             "${URL}/?sign_in=1" > /dev/null
    run_curl --data-urlencode "login=${luser}" \
             --data-urlencode "pass=${lpass}" \
             "${URL}/?sign_in=1" > /dev/null
    unset luser lpass

    # Verifica sessao
    PAGE=`run_curl "${URL}/user"`
    if echo "$PAGE" | grep -q '?exit\|sign_out\|logout'; then
        # Extrai nome do usuario do HTML
        ACC=`echo "$PAGE" | sed -n "s/.*class='white'>\([^<]*\)<.*/\1/p" | head -n1`
        [ -z "$ACC" ] && ACC="$TWM_USER"
        ACC=`echo "$ACC" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`
        export ACC
        printf "[%s] %s — login OK\n" "$TWM_TAG" "$ACC"
        return 0
    else
        printf "[%s] %s — login FALHOU\n" "$TWM_TAG" "$TWM_USER"
        return 1
    fi
}

# Tenta login
if ! login_worker; then
    [ -n "$TWM_STATUS_FILE" ] && echo "failed" > "$TWM_STATUS_FILE"
    exit 1
fi

# Configura clan e aliados
clan_id 2>/dev/null
func_proxy

# Carrega aliados se existirem
if [ ! -s "$TMP/allies.txt" ]; then
    : > "$TMP/allies.txt"
fi
if [ ! -s "$TMP/callies.txt" ]; then
    : > "$TMP/callies.txt"
fi

twm_start() {
    if echo "$RUN" | grep -q -E '[-]cv'; then
        cave_start
    elif echo "$RUN" | grep -q -E '[-]cl'; then
        twm_play
    elif echo "$RUN" | grep -q -E '[-]boot'; then
        twm_play
    else
        twm_play
    fi
}

func_unset() {
    unset HP1 HP2 YOU USER CLAN ENTER ATK ATKRND DODGE HEAL GRASS STONE BEXIT OUTGATE LEAVEFIGHT WDRED CAVE BREAK NEWCAVE
}

[ -n "$TWM_STATUS_FILE" ] && echo "running" > "$TWM_STATUS_FILE"

printf "[%s] %s — loop principal iniciado\n" "$TWM_TAG" "$ACC"

# Loop principal
while true; do
    twm_start
done
