campaign_func() {
    printf "Campaign\n"
    fetch_page "/campaign/"

    if grep -q -o -E '/campaign/(go|fight|attack|end)/[?]r[=][0-9]+' "$TMP/SRC"; then
        CAMPAIGN=`grep -o -E '/campaign/(go|fight|attack|end)/[?]r[=][0-9]+' "$TMP/SRC" | head -n 1`
        BREAK=$(($(date +%s) + 90))

        while [ -n "$CAMPAIGN" ] && [ "$(date +%s)" -lt "$BREAK" ]; do
            case $CAMPAIGN in
                *go*|*fight*|*attack*|*end*)
                    fetch_page "$CAMPAIGN"
                    RESULT=`echo "$CAMPAIGN" | cut -d'/' -f3`
                    printf "Campaign -> %s\n" "$RESULT"
                    CAMPAIGN=`grep -o -E '/campaign/(go|fight|attack|end)/[?]r[=][0-9]+' "$TMP/SRC" | head -n 1`
                    ;;
            esac
        done
    fi

    printf "Campaign ok\n"
}
