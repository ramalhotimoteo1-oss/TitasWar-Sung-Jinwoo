# shellcheck disable=SC2148
arena_fault() {
    (
        run_curl "${URL}/fault" > "$TMP/SRC"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
    BREAK=$(($(date +%s) + 10))
    while grep -q -o '/fault/attack' "$TMP/SRC" || [ "$(date +%s)" -lt "$BREAK" ]; do
        ACCESS=`grep -o -E '(/fault/attack/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP/SRC" | sed -n '1p'`
        (
            run_curl "${URL}${ACCESS}" > "$TMP/SRC"
        ) </dev/null > /dev/null 2>&1 &
        time_exit 17
        printf "%s\n" "$ACCESS"
        sleep 1s
    done
    printf "fault (ok)\n"
}

arena_collFight() {
    (
        run_curl "${URL}/collfight/enterFight" > "$TMP/SRC"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
    if grep -q -o '/collfight/' "$TMP/SRC"; then
        printf "collfight ...\n"
        printf "/collfight/enterFight\n"
        ACCESS=`cat "$TMP/SRC" | sed 's/href=/\n/g' | grep 'collfight/take' | head -n1 | awk -F\' '{ print $2 }'`
        (
            run_curl "${URL}${ACCESS}" > /dev/null
        ) </dev/null > /dev/null 2>&1 &
        time_exit 17
        printf "%s\n" "$ACCESS"
        (
            run_curl "${URL}/collfight/enterFight" > /dev/null
        ) </dev/null > /dev/null 2>&1 &
        time_exit 17
        printf "/collfight/enterFight\n"
        printf "collfight (ok)\n"
    fi
}

arena_duel() {
    printf "Arena\n"

    checkQuest 3 apply
    checkQuest 4 apply

    fetch_page "/arena/"

    BREAK=$(($(date +%s) + 60))
    count=0

    until grep -q -o 'lab/wizard' "$TMP/SRC" || [ "$(date +%s)" -gt "$BREAK" ]; do
        ACCESS=`grep -o -E '(/arena/attack/1/[?]r[=][0-9]+)' "$TMP/SRC" | sed -n '1p'`
        fetch_page "$ACCESS"
        count=$((count + 1))
        printf "  Attack %s\n" "$count"
        sleep 0.6s
    done

    fetch_page "/inv/bag/"
    SELL=`grep -o -E '(/inv/bag/sellAll/1/[?]r[=][0-9]+)' "$TMP/SRC" | sed -n '1p'`
    fetch_page "$SELL"

    checkQuest 3 end
    checkQuest 4 end

    printf "Sell all items ok\n"
    printf "Arena ok\n"
}

arena_fullmana() {
    printf "energy arena ...\n"
    (
        run_curl "${URL}/arena/quit" | sed "s/href='/\n/g" | grep 'attack/1' | head -n1 | awk -F/ '{ print $5 }' | tr -cd '[:digit:]' > "$TMP/ARENA"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
    printf " - 1 Attack...\n"
    (
        run_curl "${URL}/arena/attack/1/?r=`cat "$TMP/ARENA"`" | sed "s/href='/\n/g" | grep 'arena/lastPlayer' | head -n1 | awk -F\' '{ print $1 }' | tr -cd '[:digit:]' > "$TMP/ATK1"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
    printf " - Full Attack...\n"
    (
        run_curl "${URL}/arena/lastPlayer/?r=`cat "$TMP/ATK1"`&fullmana=true" > /dev/null
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
    printf "Energy arena ok\n"
}
