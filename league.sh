# shellcheck disable=SC2034
fetch_available_fights() {
    fetch_page "/league/" "$TMP/LEAGUE_SRC"

    if [ -f "$TMP/LEAGUE_SRC" ]; then
        printf "Looking for available fights...\n"
        AVAILABLE_FIGHTS=`grep -o -E '<b>[0-5]</b>' "$TMP/LEAGUE_SRC" | head -n 1 | sed -n 's/.*<b>\([0-5]\)<\/b>.*/\1/p'`

        case "$AVAILABLE_FIGHTS" in
            [0-5])
                printf "Available fights: %s\n" "$AVAILABLE_FIGHTS"
                ;;
            *)
                printf "Error: No available fights or not found.\n" >> "$TMP/ERROR_DEBUG"
                AVAILABLE_FIGHTS=0
                ;;
        esac
    else
        printf "The LEAGUE_SRC file was not found.\n" >> "$TMP/ERROR_DEBUG"
        AVAILABLE_FIGHTS=0
    fi

    AVAILABLE_FIGHTS=${AVAILABLE_FIGHTS:-0}
    [ "$AVAILABLE_FIGHTS" -gt 0 ]
}

get_enemy_stat() {
    index=$1
    stat_num=$2
    attempts=0
    max_attempts=10

    while [ "$attempts" -lt "$max_attempts" ]; do
        stat=`grep -o -E ': [0-9]+' "$TMP/SRC" | sed -n "$((index + stat_num))s/: //p" | tr -d '()' | tr -d ' '`

        if [ -n "$stat" ] && [ "$stat" -gt 49 ]; then
            echo "$stat"
            return 0
        fi
        stat_num=$((stat_num + 1))
        attempts=$((attempts + 1))
    done

    printf "Error: Stat not found after %s attempts.\n" "$max_attempts" >> "$TMP/ERROR_DEBUG"
    return 1
}

league_play() {
    printf "League\n"
    load_config
    checkQuest 2 apply
    checkQuest 1 apply

    PLAYER_STRENGTH=`player_stats`
    fetch_available_fights

    action="check_fights"
    fights_done=0
    j=1
    enemy_index=1
    FUNC_play_league=`get_config "FUNC_play_league"`

    while [ "$AVAILABLE_FIGHTS" -gt 0 ]; do
        case "$action" in
            check_fights)
                fetch_page "/league/"
                click=`grep -o -E "/league/fight/[0-9]{1,3}/\?r=[0-9]{1,8}" "$TMP/SRC" | sed -n "${j}p"`

                if [ -n "$click" ]; then
                    ENEMY_NUMBER=`echo "$click" | grep -o -E '[0-9]+' | head -n 1`
                    INDEX=$(((enemy_index - 1) * 4))
                    E_STRENGTH=`get_enemy_stat "$INDEX" 1`
                    E_HEALTH=`get_enemy_stat "$INDEX" 2`
                    E_AGILITY=`get_enemy_stat "$INDEX" 3`
                    E_PROTECTION=`get_enemy_stat "$INDEX" 4`
                    printf "Enemy Number: %s\n" "$ENEMY_NUMBER"

                    if [ "$AVAILABLE_FIGHTS" -eq 0 ] && [ "$ENEMY_NUMBER" -gt "$FUNC_play_league" ]; then
                        printf "Refreshed fights\n"
                        click=`grep -o -E "/league/refreshFights/\?r=[0-9]+" "$TMP/SRC" | sed -n 1p`
                        fetch_page "$click"
                        enemy_index=1
                        j=1
                    fi
                    action="fight_or_skip"
                else
                    printf "No fight buttons found for button %s\n" "$j" >> "$TMP/ERROR_DEBUG"
                    action="exit_loops"
                fi
                ;;

            fight_or_skip)
                if [ "$PLAYER_STRENGTH" -gt "$E_STRENGTH" ] || [ -f "$TMP/POTION" ]; then
                    printf "Strength (%s) > enemy (%s). Fighting %s.\n" "$PLAYER_STRENGTH" "$E_STRENGTH" "$ENEMY_NUMBER"
                    fetch_page "$click"
                    fights_done=$((fights_done + 1))
                    enemy_index=1
                    j=1
                    last_click=`grep -o -E "/league/fight/[0-9]{1,3}/\?r=[0-9]{1,8}" "$TMP/SRC" | sed -n "${j}p"`
                    ENEMY_NUMBER=`echo "$last_click" | grep -o -E '[0-9]+' | head -n 1`
                    fetch_available_fights
                    action="check_fights"
                    if [ -f "$TMP/POTION" ]; then
                        rm "$TMP/POTION"
                    fi
                else
                    printf "Strength (%s) < enemy (%s). Skipping.\n" "$PLAYER_STRENGTH" "$E_STRENGTH"
                    enemy_index=$((enemy_index + 1))
                    j=$((j + 2))
                    last_click=`grep -o -E "/league/fight/[0-9]{1,3}/\?r=[0-9]{1,8}" "$TMP/SRC" | sed -n "${j}p"`
                    ENEMY_NUMBER=`echo "$last_click" | grep -o -E '[0-9]+' | head -n 1`
                    fetch_available_fights
                    if [ -z "$last_click" ] && [ "$AVAILABLE_FIGHTS" -gt 1 ]; then
                        printf "Reached the last enemy. Attacking and using a potion...\n"
                        j=$((j - 2))
                        click=`grep -o -E "/league/fight/[0-9]{1,3}/\?r=[0-9]{1,8}" "$TMP/SRC" | sed -n "${j}p"`
                        fetch_page "$click"
                        fights_done=$((fights_done + 1))
                        fetch_available_fights
                        sleep 1s
                        potion_click=`grep -o -E "/league/potion/\?r=[0-9]+" "$TMP/SRC" | sed -n 1p`
                        fetch_page "$potion_click"
                        printf "Used a potion\n"
                        echo "potion used" > "$TMP/POTION"
                        E_STRENGTH=50
                        enemy_index=1
                        j=1
                        action="check_fights"
                    else
                        action="check_fights"
                    fi
                fi
                ;;

            exit_loops)
                break
                ;;
        esac

        case "$AVAILABLE_FIGHTS" in
            *[!0-9]*)
                printf "Error: %s is not a valid number.\n" "$AVAILABLE_FIGHTS" >> "$TMP/ERROR_DEBUG"
                AVAILABLE_FIGHTS=0
                ;;
            *)
                if [ "$AVAILABLE_FIGHTS" -eq 0 ]; then
                    clickReward=`grep -o -E "/league/takeReward/\?r=[0-9]+" "$TMP/SRC" | sed -n 1p`
                    if [ -n "$clickReward" ]; then
                        fetch_page "$clickReward"
                        printf "Claimed reward\n"
                    fi
                fi
                ;;
        esac
    done

    unset click ENEMY_NUMBER PLAYER_STRENGTH E_STRENGTH AVAILABLE_FIGHTS fights_done enemy_index j

    checkQuest 2 end
    checkQuest 1 end

    printf "League Routine Completed ok\n"
}
