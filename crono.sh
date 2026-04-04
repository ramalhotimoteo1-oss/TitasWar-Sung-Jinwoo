# shellcheck disable=SC2154
# shellcheck disable=SC2317
func_crono() {
    HOUR=`date +%H | sed 's/^0//'`
    MIN=`date +%M | sed 's/^0//'`
    printf "%s %s\n" "$URL" "`date +%H:%M`"
}

func_cat() {
    func_crono
    cat "$TMP/msg_file"

    info() {
        printf "\n"
        grep -o -E '[[:alpha:]]+?[_]?[[:alpha:]]+?[ ]?\(\) \{' "$HOME"/twm/*.sh | awk -F: '{ print $2 }' | awk -F'(' '{ print $1 }'
        read -r -t 30
    }

    while true; do
        printf "No battles now, waiting %ss\n" "$i"
        printf "Enter a command (or 'info' / 'config'):\n"

        read -r -t "$i" cmd

        if [ "$cmd" = " " ]; then
            break
        fi

        printf "\n"

        case "$cmd" in
            config|requer_func)
                $cmd
                sleep 0.5s
                continue
                ;;
            *)
                $cmd
                break
                ;;
        esac
    done
}

func_sleep() {
    if [ "`date +%d`" -eq 01 ]; then
        if [ "$HOUR" -lt 9 ]; then
            coliseum_start
            reset; clear
            i=60
            func_cat
        fi
    fi

    if [ "$MIN" -ge 29 ] && [ "$MIN" -le 30 ]; then
        reset; clear
        i=15
        func_cat
    else
        reset; clear
        i=60
        func_cat
    fi
}

start() {
    load_config
    pause_missions_weekend
    arena_duel
    career_func
    cave_routine
    func_trade
    campaign_func
    clanDungeon
    clan_statue
    check_missions
    check_rewards

    if [ "${FUNC_auto_events:-y}" = "y" ]; then
        specialEvent
    fi

    if [ "${FUNC_clan_missions:-y}" = "y" ]; then
        clanQuests
    fi

    messages_info
    func_crono
    func_sleep
}
