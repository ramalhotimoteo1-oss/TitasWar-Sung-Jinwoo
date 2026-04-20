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

# Carrega modulos
. "$TWMDIR/info.sh"
. "$TWMDIR/session_check.sh"
colors

RUN=`cat "$TWMDIR/runmode_file" 2>/dev/null || echo '-boot'`

# Google Cloud SSH: sem termux-wake-lock necessario
# O processo e mantido vivo pelo worker.sh + screen/tmux

cd "$TWMDIR" || exit 1
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

# Arquivos de aliados
[ ! -f "$TMP/allies.txt" ]   && : > "$TMP/allies.txt"
[ ! -f "$TMP/callies.txt" ]  && : > "$TMP/callies.txt"

printf "[%s] %s — iniciando\n" "$TWM_TAG" "$TWM_USER"

# Login com retry — nunca mata o worker por falha de login
# Tenta indefinidamente com delay crescente
do_login() {
    cript_file="$TMP/cript_file"
    [ ! -f "$cript_file" ] && printf "[%s] %s — ERRO: sem credenciais\n" "$TWM_TAG" "$TWM_USER" && return 1

    creds=`base64 -d "$cript_file" 2>/dev/null`
    luser=`echo "$creds" | sed 's/login=//;s/&pass=.*//'`
    lpass=`echo "$creds" | sed 's/.*&pass=//'`
    unset creds

    # POST de login 2x
    run_curl --data-urlencode "login=${luser}" \
             --data-urlencode "pass=${lpass}" \
             "${URL}/?sign_in=1" > /dev/null
    run_curl --data-urlencode "login=${luser}" \
             --data-urlencode "pass=${lpass}" \
             "${URL}/?sign_in=1" > /dev/null
    unset luser lpass

    # Verifica sessao
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

# Loop de login com retry e delay crescente
login_delay=30
while true; do
    if do_login; then
        break
    fi
    printf "[%s] %s — login falhou, tentando novamente em %ss\n" \
        "$TWM_TAG" "$TWM_USER" "$login_delay"
    [ -n "$TWM_STATUS_FILE" ] && echo "login_retry" > "$TWM_STATUS_FILE"
    sleep "$login_delay"
    # Delay cresce ate 5min, depois estabiliza
    [ "$login_delay" -lt 300 ] && login_delay=$((login_delay * 2))
    [ "$login_delay" -gt 300 ] && login_delay=300
    # Limpa cookie para novo handshake
    rm -f "$TMP_COOKIE"
done

clan_id 2>/dev/null
func_proxy

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

while true; do
    twm_start
done
