#!/bin/sh
# shellcheck disable=SC1091
# twm.sh - Worker de conta individual (nao interativo)

if [ -z "$TWMDIR" ]; then
    _d=`dirname "$0"`
    TWMDIR=`cd "$_d" && pwd`
    unset _d
    export TWMDIR
fi

# Valida variaveis obrigatorias injetadas pelo play.sh
if [ -z "$TWM_SRV" ] || [ -z "$TWM_URL" ] || [ -z "$TWM_ACC_DIR" ]; then
    printf "ERRO: twm.sh deve ser chamado pelo play.sh\n"
    exit 1
fi

# Variaveis de ambiente da conta
URL="$TWM_URL"
UR="$TWM_SRV"
TMP="$TWM_ACC_DIR"
TMP_COOKIE="$TMP/cookie.txt"
export URL UR TMP TMP_COOKIE

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

# Carrega modulos base
. "$TWMDIR/info.sh"
. "$TWMDIR/session_check.sh"
colors

# RUN seguro
RUN=`cat "$TWMDIR/runmode_file" 2>/dev/null`
[ -z "$RUN" ] && RUN="-boot"

# Mantem acordado no Termux
if [ -d /data/data/com.termux/files/usr/share/doc ]; then
    termux-wake-lock 2>/dev/null
fi

cd "$TWMDIR" || exit 1

# Carrega libs
for _lib in \
    language.sh requeriments.sh loginlogoff.sh \
    flagfight.sh clanid.sh crono.sh arena.sh coliseum.sh \
    campaign.sh run.sh altars.sh clandmg.sh clanfight.sh \
    clancoliseum.sh king.sh undying.sh trade.sh career.sh \
    cave.sh allies.sh svproxy.sh check.sh league.sh \
    specialevent.sh function.sh update_check.sh
do
    [ -f "$TWMDIR/$_lib" ] && . "$TWMDIR/$_lib"
done
unset _lib

type translate_and_cache > /dev/null 2>&1 || translate_and_cache() { echo "$2"; }

language_setup
load_config

# userAgent
if [ ! -f "$TMP/userAgent.txt" ] && [ -f "$TWMDIR/userAgent.txt" ]; then
    cp "$TWMDIR/userAgent.txt" "$TMP/userAgent.txt"
fi

random_ua 2>/dev/null
[ -z "$vUserAgent" ] && vUserAgent="Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36"
export vUserAgent

# Arquivos auxiliares
[ ! -f "$TMP/allies.txt" ] && : > "$TMP/allies.txt"
[ ! -f "$TMP/callies.txt" ] && : > "$TMP/callies.txt"

printf "[%s] %s — iniciando\n" "$TWM_TAG" "$TWM_USER"

# =========================
# LOGIN COM RETRY INFINITO
# =========================
do_login() {

    cript_file="$TMP/cript_file"
    [ ! -f "$cript_file" ] && return 1

    creds=`base64 -d "$cript_file" 2>/dev/null`
    luser=`echo "$creds" | sed 's/login=//;s/&pass=.*//'`
    lpass=`echo "$creds" | sed 's/.*&pass=//'`
    unset creds

    run_curl --data-urlencode "login=${luser}" \
             --data-urlencode "pass=${lpass}" \
             "${URL}/?sign_in=1" > /dev/null

    run_curl --data-urlencode "login=${luser}" \
             --data-urlencode "pass=${lpass}" \
             "${URL}/?sign_in=1" > /dev/null

    unset luser lpass

    PAGE=`run_curl "${URL}/user"`

    if is_logged_in "$PAGE"; then
        ACC=`extract_username "$PAGE"`
        [ -z "$ACC" ] && ACC="$TWM_USER"
        export ACC
        printf "[%s] %s — login OK\n" "$TWM_TAG" "$ACC"
        return 0
    fi

    return 1
}

# loop login
login_delay=20

while true; do

    if do_login; then
        break
    fi

    printf "[%s] %s — login retry em %ss\n" \
        "$TWM_TAG" "$TWM_USER" "$login_delay"

    [ -n "$TWM_STATUS_FILE" ] && echo "login_retry" > "$TWM_STATUS_FILE"

    sleep "$login_delay"

    rm -f "$TMP_COOKIE"

    [ "$login_delay" -lt 120 ] && login_delay=$((login_delay + 10))

done

# =========================
# INICIALIZAÇÃO
# =========================

clan_id 2>/dev/null
func_proxy

twm_start() {

    if echo "$RUN" | grep -q -- "-cv"; then
        cave_start
        return
    fi

    if echo "$RUN" | grep -q -- "-cl"; then
        twm_play
        return
    fi

    twm_play
}

func_unset() {
    unset HP1 HP2 YOU USER CLAN ENTER ATK ATKRND DODGE HEAL
    unset GRASS STONE BEXIT OUTGATE LEAVEFIGHT WDRED
    unset CAVE BREAK NEWCAVE
}

[ -n "$TWM_STATUS_FILE" ] && echo "running" > "$TWM_STATUS_FILE"

printf "[%s] %s — loop principal iniciado\n" "$TWM_TAG" "$ACC"

# =========================
# LOOP PRINCIPAL ESTÁVEL
# =========================

while true
do
    twm_start
    sleep 2
done
