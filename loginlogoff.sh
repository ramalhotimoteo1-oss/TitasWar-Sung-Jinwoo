# shellcheck disable=SC2148
# loginlogoff.sh
# Neste modelo multi-conta o login principal e feito pelo twm.sh (login_worker)
# Esta funcao e mantida para compatibilidade com modulos que chamam login_logoff()
# e para relogin automatico em caso de sessao expirada

login_logoff() {
    # Verifica se sessao ainda esta ativa
    PAGE=`run_curl "${URL}/user"`

    if echo "$PAGE" | grep -q '?exit\|sign_out\|logout'; then
        # Sessao ativa — extrai ACC atualizado
        _acc=`echo "$PAGE" | sed -n "s/.*class='white'>\([^<]*\)<.*/\1/p" | head -n1`
        [ -n "$_acc" ] && ACC=`echo "$_acc" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`
        unset _acc
        messages_info
        clan_id
        return 0
    fi

    # Sessao expirada — tenta relogin automatico
    printf "[%s] %s — sessao expirada, reconectando...\n" "$TWM_TAG" "$TWM_USER"

    cript_file="$TMP/cript_file"
    [ ! -f "$cript_file" ] && return 1

    creds=`base64 -d "$cript_file" 2>/dev/null`
    luser=`echo "$creds" | sed 's/login=//;s/&pass=.*//'`
    lpass=`echo "$creds" | sed 's/.*&pass=//'`
    unset creds

    rm -f "$TMP_COOKIE"

    run_curl --data-urlencode "login=${luser}" \
             --data-urlencode "pass=${lpass}" \
             "${URL}/?sign_in=1" > /dev/null
    run_curl --data-urlencode "login=${luser}" \
             --data-urlencode "pass=${lpass}" \
             "${URL}/?sign_in=1" > /dev/null
    unset luser lpass

    PAGE=`run_curl "${URL}/user"`
    if echo "$PAGE" | grep -q '?exit\|sign_out\|logout'; then
        printf "[%s] %s — reconectado com sucesso\n" "$TWM_TAG" "$TWM_USER"
        messages_info
        clan_id
        return 0
    fi

    printf "[%s] %s — falha ao reconectar\n" "$TWM_TAG" "$TWM_USER"
    [ -n "$TWM_STATUS_FILE" ] && echo "failed" > "$TWM_STATUS_FILE"
    return 1
}
