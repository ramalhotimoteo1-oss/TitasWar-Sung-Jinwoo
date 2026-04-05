update() {
    if [ -z "$*" ]; then
        version="master"
    else
        version="$*"
    fi

    SERVER="https://raw.githubusercontent.com/hugoviegas/TitansWarPro/${version}/"

    # Lista de scripts (sh nao suporta arrays, usamos string separada por espaco)
    SCRIPTS="info.sh easyinstall.sh allies.sh altars.sh arena.sh campaign.sh career.sh cave.sh \
             check.sh clancoliseum.sh clandmg.sh clanfight.sh clanid.sh coliseum.sh \
             crono.sh function.sh king.sh language.sh league.sh \
             loginlogoff.sh play.sh requeriments.sh run.sh svproxy.sh \
             specialevent.sh trade.sh twm.sh undying.sh update.sh update_check.sh"

    files_to_update=""

    cd "$TWMDIR" || exit
    . language.sh
    . info.sh
    load_config

    printf "Looking for new updates, please wait...\n"

    for script in $SCRIPTS; do
        remote_count=`curl -s -L "${SERVER}${script}" | wc -c`

        if [ -e "$TWMDIR/$script" ]; then
            local_count=`wc -c < "$TWMDIR/$script"`
        else
            local_count=0
        fi

        if [ "$local_count" -ne "$remote_count" ]; then
            files_to_update="$files_to_update $script"
        fi
    done

    while true; do
        if [ -n "$files_to_update" ]; then
            printf "New updates available for:\n"
            for file in $files_to_update; do
                printf " - %s\n" "$file"
            done

            if [ "$FUNC_AUTO_UPDATE" = "y" ]; then
                choice="y"
            else
                printf "Do you want to update these files? (y/n) [The script will be restarted]: "
                read -r -n 1 choice
                echo
            fi

            case "$choice" in
                s|S|y|Y)
                    for file in $files_to_update; do
                        curl -s -L "${SERVER}${file}" -o "$TWMDIR/$file"
                        printf "Updated: %s\n" "$file"
                    done
                    ;;
                *)
                    printf "Update canceled.\n"
                    break
                    ;;
            esac

            printf "All files are updated, the script will be restarted in 3 seconds.\n"
            sleep 3
            restart_script
            break
        else
            printf "All files are updated.\n"
            sleep 1
            break
        fi
    done

    # Converte de DOS para Unix
    find "$TWMDIR" -type f -name '*.sh' -print0 | xargs -0 sed -i 's/\r$//' 2>/dev/null
    chmod +x "$TWMDIR/"*.sh &
}
