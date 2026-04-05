# shellcheck disable=SC2148
login_logoff() {

 # Garante que TMP existe antes de qualquer operacao
 mkdir -p "$TMP"

 # TMP_COOKIE definido no inicio — run_curl ja usa cookie em todas as chamadas
 TMP_COOKIE="$TMP/cookie.txt"
 export TMP_COOKIE

 # Se ja existe credencial salva, tenta relogar automaticamente
 if [ -f "$TMP/cript_file" ]; then
  printf "Setting session cookie...\n"
  SAVED=`base64 -d "$TMP/cript_file" 2>/dev/null`
  SAVED_USER=`echo "$SAVED" | sed 's/login=//;s/&pass=.*//'`
  SAVED_PASS=`echo "$SAVED" | sed 's/.*&pass=//'`
  run_curl --data-urlencode "login=${SAVED_USER}" --data-urlencode "pass=${SAVED_PASS}" "${URL}/?sign_in=1" > /dev/null
  run_curl --data-urlencode "login=${SAVED_USER}" --data-urlencode "pass=${SAVED_PASS}" "${URL}/?sign_in=1" > /dev/null
  unset SAVED SAVED_USER SAVED_PASS
  echo_t "Session configured."
 fi

 # Verifica se a sessao esta ativa
 run_curl "${URL}/user" | grep "\[level" | grep -o -E "[[:space:]][[:upper:]][[:lower:]]{0,15}[[:space:]]{0,1}[[:upper:]]{0,1}[[:lower:]]{0,14}[[:space:]]" > "$TMP/acc_file"

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
   run_curl "${URL}/?exit" > /dev/null

   echo_t "In case of error will repeat" "${BLACK_YELLOW}" "${COLOR_RESET}"
   printf "Username: "
   read -r username
   printf "Password: "

   # stty -echo: oculta digitacao da senha — compativel com sh do Termux
   # read -s NAO funciona em sh, apenas em bash
   stty -echo 2>/dev/null
   read -r password
   stty echo 2>/dev/null
   printf "\n"

   echo_t "Please wait..."

   # Salva credencial em base64
   printf "login=%s&pass=%s" "$username" "$password" | base64 -w 0 > "$TMP/cript_file"
   chmod 600 "$TMP/cript_file"

   unset username password

   # Login 2x — igual ao comportamento original
   echo_t "Setting session cookie..."
   SAVED=`base64 -d "$TMP/cript_file" 2>/dev/null`
   SAVED_USER=`echo "$SAVED" | sed 's/login=//;s/&pass=.*//'`
   SAVED_PASS=`echo "$SAVED" | sed 's/.*&pass=//'`
   run_curl --data-urlencode "login=${SAVED_USER}" --data-urlencode "pass=${SAVED_PASS}" "${URL}/?sign_in=1" > /dev/null
   run_curl --data-urlencode "login=${SAVED_USER}" --data-urlencode "pass=${SAVED_PASS}" "${URL}/?sign_in=1" > /dev/null
   unset SAVED SAVED_USER SAVED_PASS
   echo_t "Session configured."
  }
  log_in

  clear
  echo_t "Please wait..."

  # Verifica sessao apos login
  run_curl "${URL}/user" | grep "\[level" | grep -o -E "[[:space:]][[:upper:]][[:lower:]]{0,15}[[:space:]]{0,1}[[:upper:]]{0,1}[[:lower:]]{0,14}[[:space:]]" > "$TMP/acc_file"

  echo_t "Checking if user matches..."
  ACC=`cat "$TMP/acc_file"`

  if [ -n "$ACC" ]; then
   break
  fi

  # Login falhou: limpa cookie para forcar novo handshake
  rm -f "$TMP_COOKIE"

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

 TMP_COOKIE="$TMP/cookie.txt"
 export TMP_COOKIE

 cd "$TMP" || exit 1

 messages_info
 clan_id
}
