twm_play() {
    echo "$RUN" > "$HOME/twm/runmode_file"

    if [ ! -s "$TMP/CLD" ]; then
        clan_id
    fi

    case `date +%H:%M` in
        (00:[0-5]5|01:[0-5]5|02:[0-5]5|03:[0-5]5)
            coliseum_fight
            ;;
        (00:00|00:30|01:00|01:30|02:00|02:30|03:00|03:30|04:00|04:30|05:00|05:30|06:00|06:30|07:00|07:30|08:00|08:30|09:00|11:30|12:00|13:00|13:30|14:30|15:30|17:00|17:30|18:00|18:30|19:30|20:00|20:30|23:00)
            start
            ;;
        (23:30)
            start
            if [ "$FUNC_AUTO_UPDATE" = "y" ]; then
                update
            fi
            ;;
        (09:5[5-9]|15:5[5-9]|21:5[5-9])
            undying_start
            start
            ;;
        (10:1[0-4]|16:1[0-4])
            flagfight_start
            ;;
        (10:2[8-9]|14:5[8-9])
            if [ -n "$CLD" ]; then
                clancoliseum_start
            fi
            start
            ;;
        (10:5[5-9]|18:5[5-9])
            if [ -n "$CLD" ]; then
                clanfight_start
            fi
            start
            ;;
        (12:2[5-9]|16:2[5-9]|22:2[5-9])
            king_start
            start
            ;;
        (13:5[5-9]|20:5[5-9])
            if [ -n "$CLD" ]; then
                altars_start
            fi
            start
            ;;
        (09:2[5-9]|21:2[5-9])
            specialEvent
            start
            ;;
        (*)
            if echo "$RUN" | grep -q -E '[-]cl'; then
                printf "Running in coliseum mode: %s\n" "$RUN"
                sleep 5s
                arena_duel
                coliseum_start
                messages_info
            fi
            func_sleep
            func_crono
            ;;
    esac
}

restart_script() {
    # Mata apenas processos twm.sh desta conta (identificados pelo TMP exportado)
    pidf=`pgrep -f "sh.*twm/twm.sh"`
    while [ -n "$pidf" ]; do
        kill -9 "$pidf" 2>/dev/null
        sleep 1s
        pidf=`pgrep -f "sh.*twm/twm.sh"`
    done
    nohup sh "$HOME/twm/twm.sh" "$RUN" >/dev/null 2>&1 &
}
