func_trade() {
    printf "Trade\n"

    fetch_page "/trade/exchange"

    ACCESS=`grep -o -E '/trade/exchange/silver/[0-9]+[?]r[=][0-9]+' "$TMP/SRC" | head -n 1`

    BREAK=$(($(date +%s) + 30))

    until [ -z "$ACCESS" ] || [ "$(date +%s)" -gt "$BREAK" ]; do
        SILVER_NUMBER=`echo "$ACCESS" | cut -d'/' -f5 | cut -d'?' -f1`
        printf "Exchange %s silver\n" "$SILVER_NUMBER"
        fetch_page "$ACCESS"
        ACCESS=`grep -o -E '/trade/exchange/silver/[0-9]+[?]r[=][0-9]+' "$TMP/SRC" | head -n 1`
    done

    printf "Trade ok\n"
}

clan_money() {
    clan_id
    if [ -n "$CLD" ]; then
        printf "Clan money ...\n"

        fetch_page "${URL}/arena/quit"
        awk_code=`sed "s/href='/\n/g" "$TMP/SRC" | grep "attack/1" | head -n 1 | awk -F\/ '{ print $5 }' | tr -cd '[:digit:]'`
        echo "$awk_code" > "$TMP/CODE"

        printf "/clan/%s/money/?r=%s&silver=1000&gold=0&confirm=true&type=limit\n" "$CLD" "`cat "$TMP/CODE"`"
        fetch_page "/clan/${CLD}/money/?r=$(cat "$TMP/CODE")&silver=1000&gold=0&confirm=true&type=limit"

        fetch_page "${URL}/arena/quit"
        awk_code=`sed "s/href='/\n/g" "$TMP/SRC" | grep "attack/1" | head -n 1 | awk -F\/ '{ print $5 }' | tr -cd '[:digit:]'`
        echo "$awk_code" > "$TMP/CODE"

        printf "/clan/%s/money/?r=%s&silver=1000&gold=0&confirm=true&type=limit\n" "$CLD" "`cat "$TMP/CODE"`"
        fetch_page "/clan/${CLD}/money/?r=$(cat "$TMP/CODE")&silver=1000&gold=0&confirm=true&type=limit"

        printf "Clan money ok\n"
    fi
}
