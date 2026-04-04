# shellcheck disable=SC2154
members_allies() {
    cd "$TMP" || exit

    echo "" >> allies.txt
    clan_id
    echo "" > callies.txt

    if [ -n "$CLD" ]; then
        printf "Updating clan members into allies\n"

        for num in `seq 5 -1 1`; do
            printf "/clan/%s/%s\n" "$CLD" "$num"
            (
                run_curl "${URL}/clan/${CLD}/${num}" | grep -o -E "[/]>([[:upper:]][[:lower:]]{0,15}[[:space:]]{0,1}[[:upper:]]{0,1}[[:lower:]]{0,14},[[:space:]])<s" | awk -F"[>]" '{print $2}' | awk -F"[,]" '{print $1}' | sed 's,\ ,_,' >> allies.txt
            ) </dev/null > /dev/null 2>&1 &
            time_exit 17
        done

        sort -u allies.txt -o allies.txt
    fi

    printf "Allies for Coliseum and King of the Immortals:\n"
    cat allies.txt
    printf "Wait to continue.\n"
    sleep 2
}

id_allies() {
    printf "Looking for allies on friends list\n"
    cd "$TMP" || exit
    printf "/mail/friends\n"

    (
        run_curl "${URL}/mail/friends" > "$TMP/SRC"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17

    NPG=`cat "$TMP/SRC" | grep -o -E '/mail/friends/([0-9]{0,4})[^[:alnum:]]{4}62[^[:alnum:]]{3}62[^[:alnum:]]' | sed 's/\/mail\/friends\/\([0-9]\{0,4\}\).*/\1/'`

    if [ -z "$NPG" ]; then
        printf "/mail/friends\n"
        (
            run_curl "${URL}/mail/friends" | sed 's,/user/,\n/user/,g' | grep '/user/' | grep '/mail/' | cut -d\< -f1 >> tmp.txt
        ) </dev/null > /dev/null 2>&1 &
        time_exit 17
    fi

    NPG=`cat "$TMP/SRC" | grep -o -E '/mail/friends/([0-9]{0,4})[^[:alnum:]]{4}62[^[:alnum:]]{3}62[^[:alnum:]]' | sed 's/\/mail\/friends\/\([0-9]\{0,4\}\).*/\1/'`

    if [ -z "$NPG" ]; then
        printf "/mail/friends\n"
        (
            run_curl "${URL}/mail/friends" | sed 's,/user/,\n/user/,g' | grep '/user/' | grep '/mail/' | cut -d\< -f1 >> tmp.txt
        ) </dev/null > /dev/null 2>&1 &
        time_exit 17
    else
        for num in `seq "$NPG" -1 1`; do
            printf "Friends list page %s\n" "$num"
            (
                run_curl "${URL}/mail/friends/${num}" | sed 's,/user/,\n/user/,g' | grep '/user/' | grep '/mail/' | cut -d\< -f1 >> tmp.txt
            ) </dev/null > /dev/null 2>&1 &
            time_exit 17
        done
    fi

    sort -u tmp.txt -o tmp.txt
    cat tmp.txt | cut -d\> -f2 | sed 's,\ ,_,' > allies.txt
}

clan_allies() {
    clan_id

    if [ -n "$CLD" ]; then
        cd "$TMP" || exit
        echo "" > callies.txt
        cut -d/ -f3 tmp.txt > ids.txt

        printf "Clan allies by Leader on friends list\n"
        Lnl=`wc -l < ids.txt`
        ts=0

        for num in `seq "$Lnl" -1 1`; do
            IDN=`sed -n "${num}p" ids.txt`
            if [ -n "$IDN" ]; then
                printf "/user/%s\n" "$IDN"
                (
                    run_curl "${URL}/user/${IDN}" > "$TMP/SRC"
                ) </dev/null > /dev/null 2>&1 &
                time_exit 17

                LEADPU=`sed 's,/clan/,\n/clan/,g' "$TMP/SRC" | grep -E "</a>, <span class='blue'|</a>, <span class='green'" | cut -d\< -f1 | cut -d\> -f2`
                alCLAN=`grep -E -o '/clan/[0-9]{1,3}' "$TMP/SRC" | tail -n1`

                printf "%s - %s\n" "$LEADPU" "$alCLAN"

                if [ -n "$LEADPU" ]; then
                    ts=$((ts + 1))
                    echo "$LEADPU" | sed 's,\ ,_,' >> callies.txt
                    printf "%s. Ally %s %s added.\n" "$ts" "$LEADPU" "$alCLAN"
                    sort -u callies.txt -o callies.txt
                fi

                sleep 1s
            fi
        done
    fi
}

conf_allies() {
    cd "$TMP" || exit
    clear

    printf "The script will consider users on your friends list and Clan as allies.\n"
    printf "1) Add/Update alliances (All Battles)\n"
    printf "2) Add/Update just Herois alliances (Coliseum/King of immortals)\n"
    printf "3) Add/Update just Clan alliances (Altars, Clan Coliseum and Clan Fight)\n"
    printf "4) Do nothing\n"

    AL=`get_config "ALLIES"`
    printf "Current alliance configuration: %s\n" "$AL"

    if [ -z "$AL" ]; then
        printf "Set up alliances [1 to 4]: "
        while true; do
            read -r -n 1 AL
            echo
            case "$AL" in
                [1-4])
                    set_config "ALLIES" "$AL"
                    break
                    ;;
                *)
                    printf "Invalid input. Please enter a value between 1 and 4:\n"
                    ;;
            esac
        done
    else
        printf "Using existing alliance configuration: %s\n" "$AL"
    fi

    case "$AL" in
        1)
            id_allies
            clan_allies
            if [ -e "$TMP/allies.txt" ]; then
                echo ""
            else
                members_allies
            fi
            printf "Alliances on all battles active\n"
            ;;
        2)
            id_allies
            if [ -s "$TMP/allies.txt" ]; then
                echo ""
            else
                members_allies
            fi
            if [ -e "$TMP/callies.txt" ]; then
                : > "$TMP/callies.txt"
            fi
            printf "Just Herois alliances now.\n"
            ;;
        3)
            id_allies
            clan_allies
            if [ -e "$TMP/allies.txt" ]; then
                : > "$TMP/allies.txt"
            fi
            printf "Just Clan alliances now.\n"
            ;;
        4)
            printf "Nothing changed.\n"
            : >> "$TMP/allies.txt"
            : >> "$TMP/callies.txt"
            ;;
        *)
            clear
            if [ -n "$AL" ]; then
                printf "Invalid option: %s\n" "$AL"
                kill -9 $$
            else
                printf "Time exceeded!\n" >> "$TMP/ERROR_DEBUG"
            fi
            ;;
    esac
}
