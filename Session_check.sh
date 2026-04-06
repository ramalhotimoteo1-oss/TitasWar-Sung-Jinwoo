#!/bin/sh
# session_check.sh
# Funcoes centrais de verificacao de sessao e extracao de username
# Usadas pelo setup.sh, twm.sh e loginlogoff.sh

# Verifica se uma pagina HTML indica sessao ativa
# Logica: pagina logada NAO contem formulario de sign_in
# e CONTEM elementos exclusivos de usuario autenticado
is_logged_in() {
    page="$1"

    # Indicadores positivos de sessao ativa (qualquer um basta)
    if echo "$page" | grep -qi '?exit\|sign_out\|\/logout'; then
        return 0
    fi

    # Indicador alternativo: presenca de [level no conteudo
    if echo "$page" | grep -q '\[level'; then
        return 0
    fi

    # Indicador alternativo: link para perfil proprio (/user/ID)
    if echo "$page" | grep -qE "href='/user/[0-9]+'"; then
        return 0
    fi

    # Nao encontrou nenhum indicador de sessao ativa
    return 1
}

# Extrai o nome do usuario do HTML da pagina /user
# Tenta multiplos padroes em cascata
extract_username() {
    page="$1"

    # Padrao 1: <span class='white'>Nome</span>
    acc=`echo "$page" | sed -n "s/.*class='white'>\([^<]*\)<.*/\1/p" | head -n1`
    [ -n "$acc" ] && echo "$acc" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' && return

    # Padrao 2: texto antes de [level
    acc=`echo "$page" | grep -o -E "[A-Za-z0-9_.][A-Za-z0-9_. -]*\[level" \
         | sed 's/\[level//' | sed 's/[[:space:]]*$//' | head -n1`
    [ -n "$acc" ] && echo "$acc" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' && return

    # Padrao 3: link /user/ID>Nome</a>
    acc=`echo "$page" | sed -n "s/.*href='\/user\/[0-9]*'>\([^<]*\)<\/a>.*/\1/p" | head -n1`
    [ -n "$acc" ] && echo "$acc" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' && return

    # Padrao 4: strip de todas as tags e busca por texto antes de [level
    acc=`echo "$page" | sed 's/<[^>]*>//g' | grep '\[level' \
         | sed 's/\[level.*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' \
         | grep -v '^$' | tail -n1`
    [ -n "$acc" ] && echo "$acc" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' && return

    echo ""
}

# Testa login e retorna 0 se bem-sucedido
# Uso: test_login URL USER PASS [cookie_file]
test_login() {
    _url="$1"
    _user="$2"
    _pass="$3"
    _cookie="${4:-/tmp/twm_test_$$.txt}"

    # POST de login
    curl -s -L \
        -A "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36" \
        -c "$_cookie" -b "$_cookie" \
        --data-urlencode "login=${_user}" \
        --data-urlencode "pass=${_pass}" \
        "${_url}/?sign_in=1" > /dev/null

    # Segunda chamada para consolidar sessao
    curl -s -L \
        -A "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36" \
        -c "$_cookie" -b "$_cookie" \
        "${_url}/?sign_in=1" > /dev/null

    # Verifica sessao na pagina /user
    _page=`curl -s -L \
        -A "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36" \
        -c "$_cookie" -b "$_cookie" \
        "${_url}/user"`

    rm -f "$_cookie"

    if is_logged_in "$_page"; then
        return 0
    fi
    return 1
}
