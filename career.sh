career_func() {
    printf "Career\n"
    fetch_page "/career/"

    if grep -q -o -E '/career/attack/[?]r[=][0-9]+' "$TMP/SRC"; then
        checkQuest 6 apply

        fetch_page "/career/"

        if grep -q -o -E '/career/(attack|take)/[?]r[=][0-9]+' "$TMP/SRC"; then
            CAREER=`grep -o -E '/career/(attack|take)/[?]r[=][0-9]+' "$TMP/SRC"`
            BREAK=$(($(date +%s) + 60))

            while [ -n "$CAREER" ] && [ "$(date +%s)" -lt "$BREAK" ]; do
                case $CAREER in
                    *attack*|*take*)
                        fetch_page "$CAREER"
                        RESULT=`echo "$CAREER" | cut -d'/' -f3`
                        printf "Career -> %s\n" "$RESULT"
                        sleep 0.5s
                        CAREER=`grep -o -E '/career/(attack|take)/[?]r[=][0-9]+' "$TMP/SRC" | sed -n '1p'`
                        ;;
                esac
            done
        fi

        checkQuest 6 end
    fi

    printf "Career ok\n"
    return 0
}
