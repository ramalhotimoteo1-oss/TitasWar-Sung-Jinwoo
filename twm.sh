#!/bin/sh
# shellcheck disable=SC1091

# Carrega info.sh primeiro (define colors, echo_t, printf_t, fetch_page, run_curl)
. "$HOME/twm/info.sh"

# Carrega config global se existir (antes de saber o TMP da conta)
if [ -f "$HOME/twm/config.cfg" ]; then
    . "$HOME/twm/config.cfg"
fi

colors
language_setup

RUN=`cat "$HOME/twm/runmode_file" 2>/dev/null || echo '-boot'`

# Termux wake lock
if [ -d /data/data/com.termux/files/usr/share/doc ]; then
    termux-wake-lock 2>/dev/null
fi

# Carrega todas as bibliotecas com dot (.) — correto para sh no Termux
cd "$HOME/twm" || exit
for _lib in \
    language.sh \
    requeriments.sh \
    loginlogoff.sh \
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
    if [ -f "$HOME/twm/$_lib" ]; then
        . "$HOME/twm/$_lib"
    else
        printf "WARNING: %s not found, skipping.\n" "$_lib"
    fi
done
unset _lib

# Fallback de seguranca: se translate_and_cache nao foi carregada, define stub
type translate_and_cache > /dev/null 2>&1 || translate_and_cache() { echo "$2"; }

script_slogan
sleep 1s

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

# Verifica se ha selecao previa de servidor
if [ -f "$HOME/twm/ur_file" ] && [ -s "$HOME/twm/ur_file" ]; then
    printf "${GREEN_BLACK}Starting with last settings used.${COLOR_RESET}\n"

    for _i in 4 3 2 1; do
        _i=$((_i - 1))
        if read -r -t 1; then
            set_config "ALLIES" ""
            : > "$TMP/allies.txt"
            : > "$HOME/twm/ur_file"
            : > "$HOME/twm/fileAgent.txt"
            unset UR UA AL
            break
        fi
        printf "${GOLD_BLACK}To reconfigure press ENTER %ss ...${COLOR_RESET}\n" "$_i"
    done
    unset _i
fi

# Inicializa ambiente: config, servidor, proxy(no-op), login
load_config
requer_func
func_proxy
login_logoff

# Apos login, TMP ja aponta para ~/.twm/${UR}_${ACC}
# Configura aliados se nao estiver em modo caverna
if [ "`get_config ALLIES`" = "" ] && [ "$RUN" != "-cv" ]; then
    conf_allies
    clear
fi

func_cat
messages_info

# Loop principal
while true; do
    twm_start
done
