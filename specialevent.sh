#!/bin/sh
specialEvent() {
    fetch_page "/"

    if grep -q "shb_text" "$TMP/SRC"; then
        event_link=`grep -o -E "<div class='shb_text'><a href='[^']+'" "$TMP/SRC" | sed -E "s/^.*href='([^']+)'.*$/\1/" | sed -n '1p'`

        if [ -n "$event_link" ]; then
            EVENT=`echo "$event_link" | cut -d'/' -f2`
            printf "Current event: %s\n" "$EVENT"
        fi
    fi

    case $EVENT in
        questrnd)
            fetch_page "$event_link"
            printf "Event Adventure\n"
            click=`grep -o -E "/questrnd/take/\?r=[0-9]{8}" "$TMP/SRC" | sed -n '1p'`
            if [ -n "$click" ]; then
                fetch_page "$click"
                printf "Claiming reward\n"
                return 0
            else
                return 1
            fi
            ;;
        fault)
            fetch_page "${event_link}"
            printf "Event fault\n"
            click=`grep -o -E "/fault/attack/\?r=[0-9]+" "$TMP/SRC" | sed -n '1p'`
            fetch_page "${click}"
            sleep 1s
            click=`grep -o -E "/fault/attack/\?r=[0-9]+" "$TMP/SRC" | sed -n '1p'`
            while true; do
                if [ -n "${click}" ]; then
                    fetch_page "${click}"
                    click=`grep -o -E "/fault/attack/\?r=[0-9]+" "$TMP/SRC" | sed -n '1p'`
                    printf "Attacking monster\n"
                else
                    printf "Event fault ok\n"
                    break
                fi
            done
            ;;
        clandmgfight)
            case `date +%H:%M` in
                09:2[5-9]|21:2[5-9])
                    clandmgfight_start
                    ;;
                *)
                    return 1
                    ;;
            esac
            ;;
        marathon)
            fetch_page "/marathon/"
            printf "Marathon event\n"
            click=`grep -o -E "/marathon/take/\?r=[0-9]+" "$TMP/SRC" | sed -n '1p'`
            if [ -n "$click" ]; then
                fetch_page "$click"
                printf "Claiming reward\n"
                return 0
            else
                return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
}
