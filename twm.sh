#!/bin/sh
# shellcheck disable=SC1091

# TWMDIR: diretorio base do projeto
# Exportado pelo play.sh; fallback para dirname do proprio twm.sh
if [ -z "$TWMDIR" ]; then
    _twm_dir=`dirname "$0"`
    TWMDIR=`cd "$_twm_dir" && pwd`
    unset _twm_dir
    export TWMDIR
fi

# Carrega info.sh primeiro (define colors, echo_t, printf_t, fetch_page, run_curl)
# language_setup() dentro do info.sh precisa de TMP — sera chamada novamente
# apos requer_func definir TMP corretamente
. "$TWMDIR/info.sh"

colors

RUN=`cat "$TWMDIR/runmode_file" 2>/dev/null || echo '-boot'`

# Termux wake lock
if [ -d /data/data/com.termux/files/usr/share/doc ]; then
    termux-wake-lock 2>/dev/null
fi

# Carrega todas as bibliotecas com dot (.)
cd "$TWMDIR" || exit
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
    if [ -f "$TWMDIR/$_lib" ]; then
        . "$TWMDIR/$_lib"
    else
        printf "WARNING: %s not found, skipping.\n" "$_lib"
    fi
done
unset _lib

# Fallback: se translate_and_cache nao foi carregada, define stub
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
if [ -f "$TWMDIR/ur_file" ] && [ -s "$TWMDIR/ur_file" ]; then
    printf "${GREEN_BLACK}Starting with last settings used.${COLOR_RESET}\n"

    for _i in 4 3 2 1; do
        _i=$((_i - 1))
        if read -r -t 1; then
            : > "$TWMDIR/ur_file"
            : > "$TWMDIR/fileAgent.txt"
            unset UR UA AL
            break
        fi
        printf "${GOLD_BLACK}To reconfigure press ENTER %ss ...${COLOR_RESET}\n" "$_i"
    done
    unset _i
fi

# Ordem correta de inicializacao:
# 1. requer_func  -> menu servidor + user-agent -> define TMP, URL, LANGUAGE
# 2. language_setup -> agora TMP existe, carrega/cria config.cfg com LANGUAGE
# 3. load_config  -> carrega todas as configuracoes do config.cfg
# 4. func_proxy   -> no-op
# 5. login_logoff -> faz login com TMP e URL ja definidos
requer_func
language_setup
load_config
func_proxy
login_logoff

# Apos login, TMP ja aponta para ~/.twm/${UR}_${ACC}
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
