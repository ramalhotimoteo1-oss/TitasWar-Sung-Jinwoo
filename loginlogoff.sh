login_logoff() {
    PAGE="$(run_curl "${URL}/user")"

    if is_logged_in "$PAGE"; then
        _acc="$(extract_username "$PAGE")"
        [ -n "$_acc" ] && ACC="$(echo "$_acc" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        unset _acc PAGE
        messages_info
        clan_id
        return 0
    fi

    printf "[%s] %s — sessao expirada, reconectando...\n" "$TWM_TAG" "$TWM_USER"

    rm -f "$TMP_COOKIE"

    cript_file="$TMP/cript_file"
    [ ! -f "$cript_file" ] && return 1

    creds="$(base64 -d "$cript_file" 2>/dev/null)"
    luser="$(echo "$creds" | sed 's/login=//;s/&pass=.*//')"
    lpass="$(echo "$creds" | sed 's/.*&pass=//')"
    unset creds

    run_curl -c "$TMP_COOKIE" -b "$TMP_COOKIE" \
        --data-urlencode "login=${luser}" \
        --data-urlencode "pass=${lpass}" \
        "${URL}/?sign_in=1" > /dev/null

    sleep 1

    run_curl -c "$TMP_COOKIE" -b "$TMP_COOKIE" \
        "${URL}/user" > /dev/null

    unset luser lpass

    PAGE="$(run_curl -c "$TMP_COOKIE" -b "$TMP_COOKIE" "${URL}/user")"

    if is_logged_in "$PAGE"; then
        printf "[%s] %s — reconectado\n" "$TWM_TAG" "$TWM_USER"
        messages_info
        clan_id
        return 0
    fi

    printf "[%s] %s — falha ao reconectar\n" "$TWM_TAG" "$TWM_USER"
    [ -n "$TWM_STATUS_FILE" ] && echo "login_retry" > "$TWM_STATUS_FILE"
    return 1
}
