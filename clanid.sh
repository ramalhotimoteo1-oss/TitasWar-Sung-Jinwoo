clan_id() {
    cd "$TMP" || exit 1

    fetch_page "/clan" "$TMP/CLD"

    CLD=`grep -o -E '/clan/[0-9]+/' "$TMP/CLD" | head -n 1 | awk -F'/' '{ print $3 }'`

    if [ -z "$CLD" ]; then
        printf "CLAN ID not found!\n"
        return 1
    else
        echo "$CLD" > "$TMP/CLD"
    fi
}

checkQuest() {
    quest_id="$1"
    action="$2"

    if [ "${FUNC_clan_missions:-y}" != "y" ]; then
        return 1
    fi

    if [ -z "$CLD" ]; then
        printf "CLAN ID not available, trying to fetch it.\n"
        clan_id
        if [ -z "$CLD" ]; then
            printf "Failed to retrieve CLAN ID.\n"
            return 1
        fi
    fi

    fetch_page "/clan/${CLD}/quest/"

    if [ ! -s "$TMP/SRC" ]; then
        printf "Source file $TMP/SRC is empty, fetch_page may have failed.\n"
        return 1
    fi

    case "$action" in
        apply)
            click=`grep -o -E "/quest/(take|help)/$quest_id/\?r=[0-9]{8}" "$TMP/SRC" | sed -n '1p'`
            ;;
        end)
            click=`grep -o -E "/quest/(deleteHelp|end)/$quest_id/\?r=[0-9]{8}" "$TMP/SRC" | sed -n '1p'`
            ;;
        *)
            return 1
            ;;
    esac

    if [ -n "$click" ]; then
        fetch_page "$click"
        return 0
    fi

    return 1
}

clanDungeon() {
    if [ -z "$CLD" ]; then
        return
    fi

    printf "Clan Dungeon\n"
    fetch_page "/clan/${CLD}/dungeon/"

    DUNGEON=`grep -o -E '/clan/[0-9]+/dungeon/(fight|take)/[?]r=[0-9]+' "$TMP/SRC" | head -n1`

    if [ -n "$DUNGEON" ]; then
        fetch_page "$DUNGEON"
        printf "Clan Dungeon ok\n"
    fi
}

clan_statue() {
    if [ "$FUNC_clan_statue" != "y" ]; then
        return
    fi

    if [ -z "$CLD" ]; then
        return
    fi

    fetch_page "/clan/${CLD}/statue/"

    STATUE=`grep -o -E '/clan/[0-9]+/statue/activate/[?]r=[0-9]+' "$TMP/SRC" | head -n1`

    if [ -n "$STATUE" ]; then
        fetch_page "$STATUE"
        printf "Clan statue activated\n"
    fi
}

clanQuests() {
    if [ -z "$CLD" ]; then
        return
    fi

    fetch_page "/clan/${CLD}/quest/"

    QUEST=`grep -o -E '/clan/[0-9]+/quest/(take|end)/[0-9]+/[?]r=[0-9]+' "$TMP/SRC" | head -n1`

    while [ -n "$QUEST" ]; do
        fetch_page "$QUEST"
        printf "Clan quest processed\n"
        fetch_page "/clan/${CLD}/quest/"
        QUEST=`grep -o -E '/clan/[0-9]+/quest/(take|end)/[0-9]+/[?]r=[0-9]+' "$TMP/SRC" | head -n1`
    done
}
