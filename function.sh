# Global variable to control loop exits
EXIT_CONFIG="n"

update_config() {
    key="$1"
    value="$2"

    if [ ! -f "$CONFIG_FILE" ]; then
        printf "Configuration file not found. Creating new...\n"
        touch "$CONFIG_FILE"
    fi

    if grep -q "^${key}=" "$CONFIG_FILE"; then
        sed -i "s/^${key}=.*/${key}=${value}/" "$CONFIG_FILE"
        printf "Configuration %s updated to %s.\n" "$key" "$value"
    else
        echo "${key}=${value}" >> "$CONFIG_FILE"
        printf "Added new configuration key %s with value %s.\n" "$key" "$value"
    fi
}

request_update() {
    key=""
    value=""
    success=1

    while [ "$success" -ne 0 ]; do
        printf "  Macro settings - type option number:\n"
        printf " 1- Collect relics. Current: %s\n" "$FUNC_check_rewards"
        printf " 2- Use elixir. Current: %s\n" "$FUNC_use_elixir"
        printf " 3- Auto update. Current: %s\n" "$FUNC_AUTO_UPDATE"
        printf " 4- Get to top in league. Current: %s\n" "$FUNC_play_league"
        printf " 5- Change language. Current: %s\n" "$LANGUAGE"
        printf " 6- Change allies. Current: %s\n" "$ALLIES"
        printf " 7- Collect mission rewards. Current: %s\n" "$FUNC_collect_mission_rewards"
        printf " 8- Pause mission rewards on weekends. Current: %s\n" "$FUNC_pause_weekends"
        printf " 9- Complete events. Current: %s\n" "$FUNC_auto_events"
        printf " A- Complete clan missions. Current: %s\n" "$FUNC_clan_missions"
        printf " B- Enable clan statue automatically. Current: %s\n" "$FUNC_clan_statue"
        printf " C- Use gold to collect 3 ores in the cave. Current: %s\n" "$FUNC_cave_boost"
        printf " Press ENTER to exit.\n"

        read -r -n 1 key

        case $key in
            1)
                printf "Collect the relics (y or n): "
                key="FUNC_check_rewards"
                ;;
            2)
                printf "Use elixir before all valleys? (y or n): "
                key="FUNC_use_elixir"
                ;;
            3)
                printf "Update the script automatically? (y or n): "
                key="FUNC_AUTO_UPDATE"
                ;;
            4)
                printf "League number to reach the top (1-999): "
                while true; do
                    read -r value
                    case "$value" in
                        [0-9]|[0-9][0-9]|[0-9][0-9][0-9])
                            set_config "FUNC_play_league" "$value"
                            break
                            ;;
                        *)
                            printf "Invalid input. Enter a number between 1 and 999: "
                            ;;
                    esac
                done
                key="FUNC_play_league"
                ;;
            5)
                printf "Change the language? (y or n): "
                menu_loop
                menu_language
                key="LANGUAGE"
                continue
                ;;
            6)
                printf "Change your allies for battle? (y or n): "
                while true; do
                    read -r -n 1 value
                    echo
                    case "$value" in
                        [yYnN]) break ;;
                        *) printf "Invalid input. Enter 'y' or 'n': " ;;
                    esac
                done
                if [ "$value" != "n" ]; then
                    set_config "ALLIES" ""
                    key="ALLIES"
                    : > "$TMP/allies.txt"
                    : > "$TMP/callies.txt"
                    conf_allies
                fi
                break
                ;;
            7)
                printf "Collect mission rewards automatically? (y or n): "
                key="FUNC_collect_mission_rewards"
                ;;
            8)
                printf "Pause mission rewards on weekends? (y or n): "
                key="FUNC_pause_weekends"
                ;;
            9)
                printf "Run special events? (y or n): "
                key="FUNC_auto_events"
                ;;
            a|A)
                printf "Complete the clan missions? (y or n): "
                key="FUNC_clan_missions"
                ;;
            b|B)
                printf "Enable clan statue automatically? (y or n): "
                key="FUNC_clan_statue"
                ;;
            c|C)
                printf "Use gold to collect 3 ores in the cave? (y or n): "
                key="FUNC_cave_boost"
                ;;
            *)
                printf "Exiting configuration update mode.\n"
                EXIT_CONFIG="y"
                return
                ;;
        esac

        case "$key" in
            FUNC_*)
                while true; do
                    read -r -n 1 value
                    echo
                    case "$value" in
                        [yYnN]) break ;;
                        *) printf "Invalid input. Please enter 'y' or 'n': " ;;
                    esac
                done
                update_config "$key" "$value"
                success=$?
                if [ "$success" -ne 0 ]; then
                    printf "Invalid key. Please try again.\n"
                else
                    printf "Configuration updated successfully!\n"
                    config
                    break
                fi
                ;;
        esac
    done
}

load_config() {
    CONFIG_FILE="$TMP/config.cfg"
    if [ -f "$CONFIG_FILE" ]; then
        . "$CONFIG_FILE"
    else
        printf "Configuration file not found. Creating config.cfg with default values.\n"

        FUNC_check_rewards="n"
        FUNC_use_elixir="n"
        FUNC_coliseum="y"
        FUNC_AUTO_UPDATE="y"
        FUNC_play_league=999
        FUNC_clan_figth="y"
        FUNC_collect_mission_rewards="n"
        FUNC_pause_weekends="n"
        FUNC_auto_events="y"
        FUNC_clan_missions="n"
        FUNC_clan_statue="y"
        FUNC_cave_boost="y"
        LANGUAGE="en"
        ALLIES=""
        SCRIPT_PAUSED="n"

        {
        echo "FUNC_check_rewards=$FUNC_check_rewards"
        echo "FUNC_use_elixir=$FUNC_use_elixir"
        echo "FUNC_coliseum=$FUNC_coliseum"
        echo "FUNC_AUTO_UPDATE=$FUNC_AUTO_UPDATE"
        echo "FUNC_play_league=$FUNC_play_league"
        echo "FUNC_clan_figth=$FUNC_clan_figth"
        echo "FUNC_collect_mission_rewards=$FUNC_collect_mission_rewards"
        echo "FUNC_pause_weekends=$FUNC_pause_weekends"
        echo "FUNC_auto_events=$FUNC_auto_events"
        echo "FUNC_clan_missions=$FUNC_clan_missions"
        echo "FUNC_clan_statue=$FUNC_clan_statue"
        echo "FUNC_cave_boost=$FUNC_cave_boost"
        echo "SCRIPT_PAUSED=$SCRIPT_PAUSED"
        echo "LANGUAGE=$LANGUAGE"
        echo "ALLIES="
        } > "$CONFIG_FILE"
    fi
}

get_config() {
    _gc_key="$1"
    load_config
    # Lê o valor diretamente do arquivo (compatível com sh, sem ${!var})
    grep -E "^${_gc_key}=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2-
}

set_config() {
    key="$1"
    value="$2"
    load_config

    grep -v "^${key}=" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" 2>/dev/null || true
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo "${key}=${value}" >> "$CONFIG_FILE"
}

config() {
    load_config
    EXIT_CONFIG="n"

    while true; do
        if [ "$EXIT_CONFIG" = "n" ]; then
            printf "Script paused. Waiting for reactivation...\n"
            sleep 1s
            request_update
        else
            printf "Exiting configuration update mode...\n"
            EXIT_CONFIG="n"
            sleep 1s
            break
        fi
    done
}

pause_missions_weekend() {
    if [ "$FUNC_pause_weekends" = "n" ]; then
        return
    fi

    current_day=`date +%u`
    current_hour=`date +%H`
    CONFIG_FILE="$TMP/config.cfg"
    [ -f "$CONFIG_FILE" ] || return

    if [ "$current_day" -eq 6 ] || [ "$current_day" -eq 7 ]; then
        sed -i "s/^FUNC_collect_mission_rewards=.*/FUNC_collect_mission_rewards=n/" "$CONFIG_FILE"
        printf "Mission rewards collection paused for the weekend.\n"
        return
    fi

    if [ "$current_day" -eq 1 ] && [ "$current_hour" -eq 0 ]; then
        sed -i "s/^FUNC_collect_mission_rewards=.*/FUNC_collect_mission_rewards=y/" "$CONFIG_FILE"
        printf "Mission rewards collection reactivated automatically.\n"
        return
    fi
}
