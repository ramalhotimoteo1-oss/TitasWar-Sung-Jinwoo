# shellcheck disable=SC2155
# shellcheck disable=SC2154

SILVER_SPENT_TOTAL=0
GOLD_SPENT_TOTAL=0

read_boost_gold_cost() {
    BOOST_GOLD_COST=`
        grep -o -E '/cave/chance/2/[?]r=[0-9]+' "$TMP/SRC" \
        | head -n1 \
        | grep -o -E "gold.png[^0-9]*[0-9][0-9,]*[KMB]?" "$TMP/SRC" \
        | grep -v -E '[KMB]' \
        | head -n1 \
        | sed -E 's/.*gold.png[^0-9]*([0-9][0-9,]*).*/\1/' \
        | tr -d "'"
    `
    BOOST_GOLD_COST=${BOOST_GOLD_COST:-0}
}

read_speedup_silver_cost() {
    SPEEDUP_SILVER_COST=`
        grep -o -E '/cave/speedUp/[^ ]+' "$TMP/SRC" \
        | head -n1 \
        | grep -o -E "silver.png[^0-9]*[0-9][0-9,]*[KMB]?" "$TMP/SRC" \
        | grep -v -E '[KMB]' \
        | head -n1 \
        | sed -E 's/.*silver.png[^0-9]*([0-9][0-9,]*).*/\1/' \
        | tr -d ','
    `
    SPEEDUP_SILVER_COST=${SPEEDUP_SILVER_COST:-0}
}

check_cave_limits() {
    if [ "$CAVE_GOLD_LIMIT" -gt 0 ] && [ "$GOLD_SPENT_TOTAL" -ge "$CAVE_GOLD_LIMIT" ]; then
        printf "Gold limit reached (%s/%s)\n" "$GOLD_SPENT_TOTAL" "$CAVE_GOLD_LIMIT"
        sleep 3s
        echo "-boot" > "$HOME/twm/runmode_file"
        "$HOME/twm/twm.sh" -boot
        exit 0
    fi

    if [ "$CAVE_SILVER_LIMIT" -gt 0 ] && [ "$SILVER_SPENT_TOTAL" -ge "$CAVE_SILVER_LIMIT" ]; then
        printf "Silver limit reached (%s/%s)\n" "$SILVER_SPENT_TOTAL" "$CAVE_SILVER_LIMIT"
        sleep 3s
        echo "-boot" > "$HOME/twm/runmode_file"
        "$HOME/twm/twm.sh" -boot
        exit 0
    fi
}

set_cave_limits() {
    printf "Configure expenses in the Cave\n"

    while true; do
        printf "Gold limit (0 = unlimited) [current: %s]: " "$CAVE_GOLD_LIMIT"
        read -r input_gold
        case "$input_gold" in
            ''|*[!0-9]*)
                printf "Invalid value. Please enter numbers only.\n"
                ;;
            *)
                CAVE_GOLD_LIMIT="$input_gold"
                break
                ;;
        esac
    done

    while true; do
        printf "Silver limit (0 = unlimited) [current: %s]: " "$CAVE_SILVER_LIMIT"
        read -r input_silver
        case "$input_silver" in
            ''|*[!0-9]*)
                printf "Invalid value. Please enter numbers only.\n"
                ;;
            *)
                CAVE_SILVER_LIMIT="$input_silver"
                break
                ;;
        esac
    done

    printf "Defined limits! Gold: %s | Silver: %s\n" "$CAVE_GOLD_LIMIT" "$CAVE_SILVER_LIMIT"
    sleep 3s
}

check_cave_keypress() {
    key=""
    read -r -t 0.1 -n 1 key 2>/dev/null
    if [ "$key" = "x" ] || [ "$key" = "X" ]; then
        printf "Restarting in routine mode...\n"
        sleep 3s
        echo "-boot" > "$HOME/twm/runmode_file"
        "$HOME/twm/twm.sh" -boot
        exit 0
    fi
}

bottom_info() {
    printf "%s | HP %s (%s%%) | MP %s (%s%%)\n" "$ACC" "$NOWHP" "$HPPER" "$NOWMP" "$MPPER" > "$TMP/bottom_file"
    printf " ~ Press [x] to exit\n" >> "$TMP/bottom_file"
    cat "$TMP/bottom_file"
}

cave_start() {
    clan_id
    fetch_page "/cave/"
    set_cave_limits

    while echo "$RUN" | grep -q -E '[-]cv'; do
        CAVE=`grep -o -E '/cave/(gather|down|speedUp)/[?]r[=][0-9]+' "$TMP/SRC" | sed -n '1p'`
        RESULT=`echo "$CAVE" | cut -d'/' -f3`

        RESOURCES=`grep -o -E 'res/[0-9]+\.png' "$TMP/SRC" | sed 's/res\///;s/.png//'`
        MINERALS_FOUND=`echo "$RESOURCES" | grep -E '^[1-5]$' | wc -l`
        HERBS_FOUND=`echo "$RESOURCES" | grep -E '^(6|7|8|9)$' | wc -l`
        BOOST_LINK=`grep -o -E '/cave/chance/2/[?]r=[0-9]+' "$TMP/SRC" | head -n 1`

        CAN_ATTACK_MONSTER=${CAN_ATTACK_MONSTER:-0}
        MONSTER_ATTACK=`grep -o -E '/cave/attack/[?]r=[0-9]+' "$TMP/SRC" | head -n1`
        MONSTER_RUNAWAY=`grep -o -E '/cave/runaway/[?]r=[0-9]+' "$TMP/SRC" | head -n1`

        check_cave_keypress

        if [ "$MINERALS_FOUND" -eq 3 ] && [ "$HERBS_FOUND" -eq 0 ] && [ -n "$BOOST_LINK" ]; then
            read_boost_gold_cost
            printf "3 ores detected! Increasing chance by 100%%\n"
            fetch_page "$BOOST_LINK"
            if [ "$BOOST_GOLD_COST" -gt 0 ]; then
                GOLD_SPENT_TOTAL=$((GOLD_SPENT_TOTAL + BOOST_GOLD_COST))
                CAN_ATTACK_MONSTER=1
            fi
        fi

        if [ -n "$MONSTER_ATTACK" ] && [ -n "$MONSTER_RUNAWAY" ]; then
            if [ "$CAN_ATTACK_MONSTER" -eq 1 ]; then
                printf "Monster found - attacking (gold spent)\n"
                fetch_page "$MONSTER_ATTACK"
            else
                printf "Monster found - running away (no gold spent)\n"
                fetch_page "$MONSTER_RUNAWAY"
            fi
        fi

        read_speedup_silver_cost
        fetch_page "$CAVE"

        case $RESULT in
            down*)
                printf "New search\n"
                CAN_ATTACK_MONSTER=0
                ;;
            gather*)
                printf "Start mining\n"
                ;;
            speedUp*)
                printf "Speeding up mining\n"
                ;;
        esac

        if [ "$SPEEDUP_SILVER_COST" -gt 0 ]; then
            SILVER_SPENT_TOTAL=$((SILVER_SPENT_TOTAL + SPEEDUP_SILVER_COST))
        fi

        bottom_info
        fetch_page "/cave/"
        check_cave_limits
    done
}

cave_routine() {
    printf "Cave\n"

    if checkQuest 5 apply; then
        count=0
        printf "Quests available speeding up mine to complete!\n"
    else
        count=8
    fi

    fetch_page "/cave/"

    while true; do
        CAVE=`grep -o -E '/cave/(gather|down|runaway|speedUp)/[?]r[=][0-9]+' "$TMP/SRC" | sed -n '1p'`
        RESULT=`echo "$CAVE" | cut -d'/' -f3`

        RESOURCES=`grep -o -E 'res/[0-9]+\.png' "$TMP/SRC" | sed 's/res\///;s/.png//'`
        MINERALS_FOUND=`echo "$RESOURCES" | grep -E '^[1-5]$' | wc -l`
        HERBS_FOUND=`echo "$RESOURCES" | grep -E '^(6|7|8|9)$' | wc -l`
        BOOST_LINK=`grep -o -E '/cave/chance/2/[?]r=[0-9]+' "$TMP/SRC" | head -n 1`

        if [ "$FUNC_cave_boost" = "y" ]; then
            if [ "$MINERALS_FOUND" -eq 3 ] && [ "$HERBS_FOUND" -eq 0 ] && [ -n "$BOOST_LINK" ]; then
                printf "3 ores detected! Increasing chance by 100%%\n"
                fetch_page "$BOOST_LINK"
            fi
        fi

        if [ "$RESULT" = "speedUp" ] && [ "$count" -ge 8 ]; then
            printf "Cave limit reached\n"
            break
        fi

        case $RESULT in
            gather|down|runaway|speedUp)
                fetch_page "$CAVE"
                case $RESULT in
                    down*)
                        printf "New search\n"
                        count=$((count + 1))
                        ;;
                    gather*)
                        printf "Start mining\n"
                        ;;
                    runaway*)
                        printf "Running away\n"
                        ;;
                    speedUp*)
                        printf "Speed up mining\n"
                        ;;
                esac
                ;;
        esac

        fetch_page "/cave/"
    done

    checkQuest 5 end
    printf "Cave ok\n"
}
