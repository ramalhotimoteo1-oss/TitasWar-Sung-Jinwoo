# shellcheck disable=SC2148
login_logoff() {

 # Se ja existe credencial salva, tenta relogar automaticamente
 if [ -f "$TMP/cript_file" ]; then
  post_data=`cat "$TMP/cript_file" | base64 -d`
  printf "Setting session cookie...\n"
  (
   run_curl --data-raw "$post_data" "$URL/?sign_in=1" > /dev/null
  ) </dev/null > /dev/null 2>&1 &
  time_exit 17
  echo_t "Session configured."
 fi

 # Tenta obter o nome da conta logada
 (
  run_curl "$URL/user" | grep "\[level" | grep -o -E "[[:space:]][[:upper:]][[:lower:]]{0,15}[[:space:]]{0,1}[[:upper:]]{0,1}[[:lower:]]{0,14}[[:space:]]" > "$TMP/acc_file"
 ) </dev/null > /dev/null 2>&1 &
 time_exit 17

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
   (
    run_curl "$URL/?exit" > /dev/null
   ) </dev/null > /dev/null 2>&1 &
   time_exit 17

   echo_t "In case of error will repeat" "${BLACK_YELLOW}" "${COLOR_RESET}"
   echo_t "Username: "
   read -r username

   prompt=`translate_and_cache "$LANGUAGE" "Password: "`
   charcount=0
   password=""

   while read -p "$prompt" -r -s -n 1 char; do

    # NULL ou @ aceita a senha
    if [ "$char" = "" ] || [ "$char" = "$(printf '\200')" ]; then
     break
    fi

    # ESC ou DEL apaga um caractere
    if [ "$char" = "$(printf '\177')" ] || [ "$char" = "$(printf '\277')" ]; then
     if [ "$charcount" -gt 0 ]; then
      charcount=$((charcount - 1))
      prompt=`printf '\b \b'`
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

   echo_t "Please wait..." "\n"

   # Criptografia: salva credencial em base64 no diretorio da conta
   if [ -z "$ACC" ]; then
    printf "login=%s&pass=%s" "$username" "$password" | base64 -w 0 > "$TMP/cript_file"
    chmod 600 "$TMP/cript_file"
   fi

   post_data=`cat "$TMP/cript_file" | base64 -d`
   unset username password

   # Login 2x para garantir sessao ativa
   (
    run_curl --data-raw "$post_data" "$URL/?sign_in=1" > /dev/null
   ) </dev/null > /dev/null 2>&1 &
   time_exit 17
   echo_t "Setting session cookie..."
   (
    run_curl --data-raw "$post_data" "$URL/?sign_in=1" > /dev/null
   ) </dev/null > /dev/null 2>&1 &
   time_exit 17
   echo_t "Session configured."
  }
  log_in

  clear
  echo_t "Please wait..."
  (
   run_curl "$URL/user" | grep "\[level" | grep -o -E "[[:space:]][[:upper:]][[:lower:]]{0,15}[[:space:]]{0,1}[[:upper:]]{0,1}[[:lower:]]{0,14}[[:space:]]" > "$TMP/acc_file"
  ) </dev/null > /dev/null 2>&1 &
  time_exit 17
  echo_t "Checking if user matches..."
  ACC=`cat "$TMP/acc_file"`

  if [ -n "$ACC" ]; then
   break
  fi

 done

 # Redefine TMP para o diretorio definitivo da conta: ~/.twm/${UR}_${ACC}
 # Isso garante isolamento total entre multiplas contas/instancias
 ACC_SAFE=`echo "$ACC" | tr ' ' '_'`
 TMP_NEW="$HOME/.twm/${UR}_${ACC_SAFE}"

 if [ "$TMP" != "$TMP_NEW" ]; then
  mkdir -p "$TMP_NEW"
  # Migra arquivos essenciais para o diretorio da conta
  cp -n "$TMP/cript_file"   "$TMP_NEW/cript_file"   2>/dev/null
  cp -n "$TMP/userAgent.txt" "$TMP_NEW/userAgent.txt" 2>/dev/null
  cp -n "$TMP/config.cfg"   "$TMP_NEW/config.cfg"   2>/dev/null
  TMP="$TMP_NEW"
  export TMP
 fi

 TMP_COOKIE="$TMP/cookie.txt"
 export TMP_COOKIE

 cd "$TMP" || exit 1

 messages_info
 clan_id
}
