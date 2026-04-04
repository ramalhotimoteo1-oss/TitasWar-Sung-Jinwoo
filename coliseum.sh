# shellcheck disable=SC2155
coliseum_fight() {
    # Arquivos de batalha gravados no diretorio da conta (sem mktemp)
    src_ram="$TMP/col_src"
    full_ram="$TMP/col_full"

    LA=5
    HPER=38
    RPER=5

    printf "Coliseum\n"

    # HP maximo
    (
        run_curl "$URL/train" | grep -o -E '\(([0-9]+)\)' | sed 's/[()]//g' > "$full_ram"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 20

    # Desativa graficos
    (
        run_curl "$URL/settings/graphics/0" > /dev/null
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17

    # Pagina do coliseu
    (
        run_curl "$URL/coliseum" > "$src_ram"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17

    # Encerra luta pendente
    if grep -q -o '?end_fight' "$src_ram"; then
        (
            run_curl "$URL/coliseum/?end_fight=true" > /dev/null
        ) </dev/null > /dev/null 2>&1 &
        time_exit 17
        (
            run_curl "$URL/coliseum" > "$src_ram"
        ) </dev/null > /dev/null 2>&1 &
        time_exit 17
    fi

    access_link=`grep -o -E '/coliseum(/[A-Za-z]+/[?]r[=][0-9]+|/)' "$src_ram" | sed -n '1p'`
    go_stop=`grep -o -E '/coliseum/enterFight/[?]r[=][0-9]+' "$src_ram"`

    if [ -n "$go_stop" ]; then
        printf "  Entering...\n"
        (
            run_curl "${URL}${go_stop}" > "$src_ram"
        ) </dev/null > /dev/null 2>&1 &
        time_exit 17

        access_link=`grep -o -E '/coliseum(/[A-Za-z]+/[?]r[=][0-9]+|/)' "$src_ram" | grep -v 'dodge' | sed -n 1p`
        printf " Preparing for battle, waiting for other players...\n"

        first_time=`date +%s`
        until grep -q -o 'coliseum/dodge/' "$src_ram" || awk -v ltime="$(($(date +%s) - first_time))" 'BEGIN { exit !(ltime > 30) }'; do
            (
                run_curl "${URL}${access_link}" > "$src_ram"
            ) </dev/null > /dev/null 2>&1 &
            time_exit 17
            access_link=`grep -o -E '/(coliseum/[A-Za-z]+/[?]r[=][0-9]+|coliseum)' "$src_ram" | grep -v 'dodge' | sed -n 1p`
            printf " Preparing...\n"
            sleep 3s
        done

        cl_access() {
            last_heal=$(($(date +%s) - 90))
            last_dodge=$(($(date +%s) - 20))
            last_atk=$(($(date +%s) - LA))

            USH=`grep -o -E '(hp)[^A-z0-9]{1,4}[0-9]{2,5}' "$src_ram" | grep -o -E '[0-9]{2,5}' | sed 's,\ ,,g'`
            ENH=`grep -o -E '(nbsp)[^A-Za-z0-9]{1,2}[0-9]{1,6}' "$src_ram" | sed -n 's,nbsp[;],,;s,\ ,,;1p'`
            USER=`grep -o -E '([[:upper:]][[:lower:]]{0,15}( [[:upper:]][[:lower:]]{0,13})?)[[:space:]][^[:alnum:]]s' "$src_ram" | sed -n 's,\ [<]s,,;s,\ ,_,;2p'`

            ATK=`grep -o -E '/coliseum/atk/[?]r[=][0-9]+' "$src_ram" | sed -n 1p`
            ATKRND=`grep -o -E '/coliseum/atkrnd/[?]r[=][0-9]+' "$src_ram"`
            DODGE=`grep -o -E '/coliseum/dodge/[?]r[=][0-9]+' "$src_ram"`
            HEAL=`grep -o -E '/coliseum/heal/[?]r[=][0-9]+' "$src_ram"`

            RHP=`awk -v ush="$USH" -v rper="$RPER" 'BEGIN { printf "%.0f", ush * rper / 100 + ush }'`
            HLHP=`awk -v ush="$(cat "$full_ram")" -v hper="$HPER" 'BEGIN { printf "%.0f", ush * hper / 100 }'`

            if grep -q -o '/dodge/' "$src_ram"; then
                printf "Em batalha - HP: %s\n" "$USH"
            else
                if grep -q -o '?end_fight=true' "$src_ram"; then
                    if awk -v ltime="$(($(date +%s) - first_time))" 'BEGIN { exit !(ltime < 300) }'; then
                        (
                            run_curl "${URL}/coliseum" > "$src_ram"
                        ) </dev/null > /dev/null 2>&1 &
                        time_exit 17
                        printf "Fim de batalha detectado.\n"
                    fi
                else
                    BREAK_LOOP=1
                    printf "Battle over.\n"
                    sleep 2s
                fi
            fi
        }

        cl_access
        OLDHP=$USH
        BREAK_LOOP=""
        first_time=`date +%s`

        until [ -n "$BREAK_LOOP" ]; do
            now=`date +%s`
            time_since_last_heal=$((now - last_heal))
            time_since_last_dodge=$((now - last_dodge))
            time_since_last_atk=$((now - last_atk))

            if awk -v ush="$USH" -v hlhp="$HLHP" 'BEGIN { exit !(ush < hlhp) }' && \
               [ "$time_since_last_heal" -gt 90 ] && [ "$time_since_last_heal" -lt 300 ]; then
                (
                    run_curl "${URL}${HEAL}" > "$src_ram"
                ) </dev/null > /dev/null 2>&1 &
                time_exit 17
                cl_access
                echo "$USH" > "$full_ram"
                last_heal=$now
                last_atk=$now

            elif ! grep -q -o 'txt smpl grey' "$src_ram" && \
                 [ "$time_since_last_dodge" -gt 20 ] && [ "$time_since_last_dodge" -lt 300 ] && \
                 awk -v ush="$USH" -v oldhp="$OLDHP" 'BEGIN { exit !(ush < oldhp) }'; then
                (
                    run_curl "${URL}${DODGE}" > "$src_ram"
                ) </dev/null > /dev/null 2>&1 &
                time_exit 17
                cl_access
                OLDHP=$USH
                last_dodge=$now
                last_atk=$now

            elif awk -v latk="$time_since_last_atk" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && \
                 ! grep -q -o 'txt smpl grey' "$src_ram" && \
                 awk -v rhp="$RHP" -v enh="$ENH" 'BEGIN { exit !(rhp < enh) }'; then
                (
                    run_curl "${URL}${ATKRND}" > "$src_ram"
                ) </dev/null > /dev/null 2>&1 &
                time_exit 17
                cl_access
                last_atk=$now

            elif awk -v latk="$time_since_last_atk" -v atktime="$LA" 'BEGIN { exit !(latk > atktime) }'; then
                (
                    run_curl "${URL}${ATK}" > "$src_ram"
                ) </dev/null > /dev/null 2>&1 &
                time_exit 17
                cl_access
                last_atk=$now

            else
                (
                    run_curl "${URL}/coliseum" > "$src_ram"
                ) </dev/null > /dev/null 2>&1 &
                time_exit 17
                cl_access
                sleep 1s
            fi
        done

        rm -f "$src_ram" "$full_ram"
        unset last_heal last_dodge last_atk USH ENH USER ATK ATKRND DODGE HEAL BREAK_LOOP
        func_unset

        printf "The battle is over!\n"
    else
        printf "It was not possible to start the battle at this time.\n"
    fi
}

coliseum_start() {
    if [ "$FUNC_coliseum" = "n" ]; then
        return
    fi

    if case `date +%H:%M` in
        (09:2[4-9]|09:5[4-9]|10:1[0-4]|10:2[4-9]|10:5[4-9]|12:2[4-9]|13:5[4-9]|14:5[4-9]|15:5[4-9]|16:1[0-4]|16:2[4-9]|18:5[4-9]|20:5[4-9]|21:2[4-9]|21:5[4-9]|22:2[4-9])
            exit 1
            ;;
        esac
    then
        if echo "$RUN" | grep -q -E '[-]boot'; then
            (
                run_curl "${URL}/quest/" > "$TMP/SRC"
            ) </dev/null > /dev/null 2>&1 &
            time_exit 20

            while grep -q -o -E '/coliseum/[?]quest_t[=]quest&quest_id[=]11&qz[=][a-z0-9]+' "$TMP/SRC"; do
                coliseum_fight
                (
                    run_curl "${URL}/quest/" > "$TMP/SRC"
                ) </dev/null > /dev/null 2>&1 &
                time_exit 20

                ENDQUEST=`grep -o -E '/quest/end/11[?]r[=][A_z0-9]+' "$TMP/SRC"`
                if [ -n "$ENDQUEST" ]; then
                    (
                        run_curl "${URL}${ENDQUEST}" > "$TMP/SRC"
                    ) </dev/null > /dev/null 2>&1 &
                    time_exit 20
                fi
            done

        elif echo "$RUN" | grep -q -E '[-]cl'; then
            coliseum_fight
        fi
    else
        printf "Battle or event time...\n"
        sleep 5s
    fi
}
