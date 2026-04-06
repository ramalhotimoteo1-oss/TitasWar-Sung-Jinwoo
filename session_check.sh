#!/bin/sh
# session_check.sh

is_logged_in() {
    page="$1"

    # Se ainda tem formulario de login -> nao logado
    echo "$page" | grep -qi "sign_in" && return 1

    # Indicadores de login
    echo "$page" | grep -qi "/user" && return 0
    echo "$page" | grep -qi "logout" && return 0
    echo "$page" | grep -qi "exit" && return 0
    echo "$page" | grep -qi "\[level" && return 0

    return 1
}

extract_username() {
    page="$1"

    acc=$(echo "$page" | sed -n "s/.*class='white'>\([^<]*\)<.*/\1/p" | head -n1)
    [ -n "$acc" ] && echo "$acc" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' && return

    acc=$(echo "$page" | grep -o -E "[A-Za-z0-9_.][A-Za-z0-9_. -]*\[level" \
        | sed 's/\[level//' | sed 's/[[:space:]]*$//' | head -n1)
    [ -n "$acc" ] && echo "$acc" && return

    acc=$(echo "$page" | sed -n "s/.*href='\/user\/[0-9]*'>\([^<]*\)<\/a>.*/\1/p" | head -n1)
    [ -n "$acc" ] && echo "$acc" && return

    echo ""
}

test_login() {
    _url="$1"
    _user="$2"
    _pass="$3"
    _cookie="${4:-/tmp/twm_test_$$.txt}"

    curl -s -L \
        -c "$_cookie" -b "$_cookie" \
        --data-urlencode "login=${_user}" \
        --data-urlencode "pass=${_pass}" \
        "${_url}/?sign_in=1" > /dev/null

    _page=$(curl -s -L -c "$_cookie" -b "$_cookie" "${_url}/user")

    rm -f "$_cookie"

    is_logged_in "$_page"
}
