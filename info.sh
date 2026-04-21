#!/bin/sh
# shellcheck disable=SC2034
colors() {
    BLACK_BLACK='\033[00;30m'
    BLACK_CYAN='\033[01;36m\033[01;07m'
    BLACK_GREEN='\033[00;32m\033[01;07m'
    BLACK_GRAY='\033[01;30m\033[01;07m'
    BLACK_PINK='\033[01;35m\033[01;07m'
    BLACK_RED='\033[01;31m\033[01;07m'
    BLACK_YELLOW='\033[00;33m\033[01;07m'
    CYAN_BLACK='\033[04;36m\033[02;04m'
    CYAN_CYAN='\033[01;36m\033[08;07m'
    BLUE_BLACK='\033[0;34m'
    COLOR_RESET='\033[00m'
    GOLD_BLACK='\033[0;33m'
    GREEN_BLACK='\033[32m'
    GREENb_BLACK='\033[1;32m'
    RED_BLACK='\033[0;31m'
    PURPLEi_BLACK='\033[03;34m\033[02;03m'
    PURPLEis_BLACK='\033[03;34m\033[02;04m'
    WHITE_BLACK='\033[37m'
    WHITEb_BLACK='\033[01;38m\033[05;01m'
}

script_slogan() {
    versionNum="3.9.28"
    printf "TWM - Titans War Macro v%s\n" "$versionNum"
}

language_setup() {
    CONFIG_FILE="$TMP/config.cfg"
    LANGUAGE=`grep -E "^LANGUAGE=" "$CONFIG_FILE" 2>/dev/null | cut -d '=' -f2`
    if [ -z "$LANGUAGE" ]; then
        LANGUAGE="en"
        echo "LANGUAGE=$LANGUAGE" >> "$CONFIG_FILE"
    fi
    export LANGUAGE
}
language_setup

printf_t() {
    local_text="$1"
    local_color_start="$2"
    local_color_end="$3"
    local_emoji_position="$4"
    local_emoji="$5"
    local_translated_text=`translate_and_cache "$LANGUAGE" "$local_text"`
    if [ "$local_emoji_position" = "before" ]; then
        printf "${local_color_start}%s %s${local_color_end}\n" "$local_emoji" "$local_translated_text"
    else
        printf "${local_color_start}%s %s${local_color_end}" "$local_translated_text" "$local_emoji"
    fi
}

echo_t() {
    local_text="$1"
    local_color_start="$2"
    local_color_end="$3"
    local_emoji_position="$4"
    local_emoji="$5"
    local_translated_text=`translate_and_cache "$LANGUAGE" "$local_text"`
    if [ "$local_emoji_position" = "before" ]; then
        printf "${local_color_start}%s %s${local_color_end}\n" "$local_emoji" "$local_translated_text"
    else
        printf "${local_color_start}%s %s${local_color_end}\n" "$local_translated_text" "$local_emoji"
    fi
}

time_exit() {
    (
        TEFPID=`echo "$!" | grep -o -E '([0-9]{2,6})'`
        for TELOOP in `seq "$1" -1 1`; do
            sleep 1s
            if ! kill -0 "$TEFPID" 2>/dev/null; then
                return 0
            fi
        done
        kill -s PIPE "$TEFPID" > /dev/null 2>&1
        kill -15 "$TEFPID" > /dev/null 2>&1
        printf "Command execution was interrupted!\n" >> "$TMP/ERROR_DEBUG"
    )
}

# Funcao central de requisicao via curl
# Usa TMP_COOKIE se definido; caso contrario opera sem cookie (fase pre-login)
run_curl() {
    if [ -n "$TMP_COOKIE" ]; then
        curl -s -L --max-time 30 --connect-timeout 15 \
            -A "$vUserAgent" -c "$TMP_COOKIE" -b "$TMP_COOKIE" "$@"
    else
        curl -s -L --max-time 30 --connect-timeout 15 \
            -A "$vUserAgent" "$@"
    fi
}

# Acessa qualquer pagina pelo caminho relativo
fetch_page() {
    relative_url="$1"
    output_file="${2:-$TMP/SRC}"

    (
        run_curl "${URL}${relative_url}" > "$output_file"
    ) </dev/null > /dev/null 2>&1 &

    time_exit 17
}

hpmp() {
    if echo "$@" | grep -q '\-fix'; then
        (
            run_curl "$URL/train" > "$TMP/TRAIN"
        ) </dev/null > /dev/null 2>&1 &
        time_exit 20
        FIXHP=`grep -o -E '\(([0-9]+)\)' "$TMP/TRAIN" | sed 's/[()]//g'`
        FIXMP=`grep -o -E ': [0-9]+' "$TMP/TRAIN" | sed -n '5s/: //p'`
    fi

    NOWHP=`grep -o -E "<img src='/images/icon/health.png' alt='hp'/> <span class='(dred|white)'>[ ]?[0-9]{1,7}[ ]?</span> | <img src='/images/icon/mana.png' alt='mp'/>" "$TMP/SRC" | tr -c -d '[:digit:]'`
    NOWMP=`grep -o -E "</span> | <img src='/images/icon/mana.png' alt='mp'/>[ ]?[0-9]{1,7}[ ]?</span><div class='clr'></div></div>" "$TMP/SRC" | tr -c -d '[:digit:]'`

    HPPER=`awk -v nowhp="$NOWHP" -v fixhp="$FIXHP" 'BEGIN { printf "%.3f", nowhp / fixhp * 100 }' | awk '{printf "%.2f\n", $1}'`
    MPPER=`awk -v nowmp="$NOWMP" -v fixmp="$FIXMP" 'BEGIN { printf "%.3f", nowmp / fixmp * 100 }' | awk '{printf "%.2f\n", $1}'`
}

messages_info() {
    printf "TWM - Titans War Macro v%s | %s\n" "$versionNum" "$ACC" > "$TMP/msg_file"
    printf "HP: %s (%s%%) | MP: %s (%s%%)\n" "$NOWHP" "$HPPER" "$NOWMP" "$MPPER" >> "$TMP/msg_file"
}

player_stats() {
    fetch_page "/train"
    STRENGTH=`grep -o -E ': [0-9]+' "$TMP/SRC" | sed -n '1s/: //p'`
    PLAYER_STRENGTH=`echo "$STRENGTH" | tr -cd '[:digit:]'`
    echo "$PLAYER_STRENGTH"
}
