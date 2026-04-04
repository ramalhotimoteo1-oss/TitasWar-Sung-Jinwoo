# shellcheck disable=SC2148
login_logoff() {

 # Garante que TMP existe antes de qualquer operacao
 mkdir -p "$TMP"

 # TMP_COOKIE definido logo no inicio para que run_curl ja use o cookie correto
 # em TODAS as chamadas, incluindo a verificacao inicial de sessao
 TMP_COOKIE="$TMP/cookie.txt"
 export TMP_COOKIE

 # Se ja existe credencial salva, tenta relogar automaticamente
 if [ -f "$TMP/cript_file" ]; then
  # Decodifica credencial para arquivo temporario de POST
  # O arquivo contem: login=usuario&pass=senha
  base64 -d "$TMP/cript_file" > "$TMP/post_data"
  chmod 600 "$TMP/post_data"
  printf "Setting session cookie...\n"
  # --data @arquivo le o arquivo diretamente — evita quebra com caracteres especiais na senha
  run_curl --data "@$TMP/post_data" "$URL/?sign_in=1" > /dev/null
  run_curl --data "@$TMP/post_data" "$URL/?sign_in=1" > /dev/null
  rm -f "$TMP/post_data"
  echo_t "Session configured."
 fi

 # Verifica se a sessao esta ativa buscando nome do usuario logado
 run_curl "$URL/user" | grep "\[level" | grep -o -E "[[:space:]][[:upper:]][[:lower:]]{0,15}[[:space:]]{0,1}[[:upper:]]{0,1}[[:lower:]]{0,14}[[:space:]]" > "$TMP/acc_file"

 echo_t "Checking if user matches..."
 sed -i 's/^[ \t]*//;s/[ \t]*$//' "$TMP/acc_file"
 ACC=`cat "$TMP/acc_file"`

 # Conta reconhecida: oferece 4s para trocar
 if [ -n "$ACC" ] && [ -n "$URL" ]; then
  check=4
  until [ "$check" -lt 1 ]; do
   clear
   echo_t "Please wait..."
   printf "${GOLD_BLACK}> [%s] ${COLOR_RESET}- " "$ACC"
   echo_t "To change your user account press the button" "" "${GOLD_BLACK} [ENTER] ${check}s ...${COLOR_RESET}"
   check=$((check - 1))
   if read -t 1; then
    ACC=""
    unset FIXHP FIXMP STATUS NOWHP NOWMP HPPER MPPER
    break
   fi
  done
 fi

 clear
 echo_t "Please wait..."

 # Loop de login manual enquanto ACC estiver vazio
 while [ -z "$ACC" ] && [ -n "$URL" ]; do

  log_in() {
   # Logoff antes de tentar novo login
   run_curl "$URL/?exit" > /dev/null

   echo_t "In case of error will repeat" "${BLACK_YELLOW}" "${COLOR_RESET}"
   echo_t "Username: "
   read -r username

   prompt=`translate_and_cache "$LANGUAGE" "Password: "`
   charcount=0
   password=""

   while read -p "$prompt" -r -s -n 1 char; do

    # NULL aceita a senha
    if [ "$char" = "" ]; then
     break
    fi

    # DEL apaga um caractere (octal 177)
    if [ "$char" = "`printf '\177'`" ]; then
     if [ "$charcount" -gt 0 ]; then
      charcount=$((charcount - 1))
      prompt="`printf '\b \b'`"
      password=`echo "$password" | sed 's/.$//'`
     else
      prompt=""
     fi
    else
     charcount=$((charcount + 1))
     prompt="*"
     password="${password}${char}"
    fi

   done

   printf "\n"
   echo_t "Please wait..."

   # Salva credencial em base64 (criptografia basica para nao ficar em texto puro)
   printf "login=%s&pass=%s" "$username" "$password" | base64 -w 0 > "$TMP/cript_file"
   chmod 600 "$TMP/cript_file"

   # Decodifica para arquivo de POST (curl le direto do arquivo)
   base64 -d "$TMP/cript_file" > "$TMP/post_data"
   chmod 600 "$TMP/post_data"

   unset username password

   # Login 2x — igual ao comportamento original do w3m
   # --data @arquivo garante que caracteres especiais na senha nao quebram o POST
   echo_t "Setting session cookie..."
   run_curl --data "@$TMP/post_data" "$URL/?sign_in=1" > /dev/null
   run_curl --data "@$TMP/post_data" "$URL/?sign_in=1" > /dev/null
   rm -f "$TMP/post_data"
   echo_t "Session configured."
  }
  log_in

  clear
  echo_t "Please wait..."

  # Verifica sessao apos login — cookie ja esta em TMP_COOKIE
  run_curl "$URL/user" | grep "\[level" | grep -o -E "[[:space:]][[:upper:]][[:lower:]]{0,15}[[:space:]]{0,1}[[:upper:]]{0,1}[[:lower:]]{0,14}[[:space:]]" > "$TMP/acc_file"

  echo_t "Checking if user matches..."
  ACC=`cat "$TMP/acc_file"`

  if [ -n "$ACC" ]; then
   break
  fi

 done

 # Redefine TMP para o diretorio definitivo da conta: ~/.twm/${UR}_${ACC}
 ACC_SAFE=`echo "$ACC" | tr ' ' '_'`
 TMP_NEW="$HOME/.twm/${UR}_${ACC_SAFE}"

 if [ "$TMP" != "$TMP_NEW" ]; then
  mkdir -p "$TMP_NEW"
  cp -n "$TMP/cript_file"    "$TMP_NEW/cript_file"    2>/dev/null
  cp -n "$TMP/cookie.txt"    "$TMP_NEW/cookie.txt"    2>/dev/null
  cp -n "$TMP/userAgent.txt" "$TMP_NEW/userAgent.txt" 2>/dev/null
  cp -n "$TMP/config.cfg"    "$TMP_NEW/config.cfg"    2>/dev/null
  TMP="$TMP_NEW"
  export TMP
 fi

 # Reatualiza TMP_COOKIE para o diretorio definitivo
 TMP_COOKIE="$TMP/cookie.txt"
 export TMP_COOKIE

 cd "$TMP" || exit 1

 messages_info
 clan_id
}
