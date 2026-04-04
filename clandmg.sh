#
#/clandmgfight/dodge/?r=0
#/clandmgfight/attack/?r=0
#/clandmgfight/attackrandom/?r=0
#/clandmgfight/heal/?r=0
#/clandmgfight/stone/?r=0
#/clandmgfight/grass/?r=0
#/clandmgfight/?out_gate
clandmgfight_fight() {
  cd "$TMP" || exit
  LA=4
  HPER=48
  RPER=15
  awk -v ush="$(cat FULL)" -v hper="$HPER" 'BEGIN { printf "%.0f", ush * hper / 100 }' > HLHP

  cf_access() {
    grep -o -E '(/[a-z]+/[a-z]{0,4}at[a-z]{0,3}k/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP/SRC" | sed -n '1p' > ATK 2>/dev/null
    grep -o -E '(/[a-z]+/at[a-z]{0,3}k[a-z]{3,6}/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP/SRC" > ATKRND 2>/dev/null
    grep -o -E '(/clandmgfight/dodge/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP/SRC" > DODGE 2>/dev/null
    grep -o -E '(/clandmgfight/heal/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP/SRC" > HEAL 2>/dev/null
    grep -o -E '(/clandmgfight/grass/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+)' "$TMP/SRC" > GRASS 2>/dev/null
    grep -o -E '([[:upper:]][[:lower:]]{0,20}( [[:upper:]][[:lower:]]{0,17})?)[[:space:]]\(' "$TMP/SRC" | sed -n 's,\ [(],,;s,\ ,_,;2p' > CLAN 2>/dev/null
    grep -o -E "(hp)[^A-Za-z0-9]{1,4}[0-9]{1,6}" "$TMP/SRC" | sed "s,hp[']\\/[>],,;s,\ ,," > HP 2>/dev/null
    grep -o -E "(nbsp)[^A-Za-z0-9]{1,2}[0-9]{1,6}" "$TMP/SRC" | sed -n 's,nbsp[;],,;s,\ ,,;1p' > HP2 2>/dev/null
    awk -v ush="$(cat HP)" -v rper="$RPER" 'BEGIN { printf "%.0f", ush * rper / 100 + ush }' > RHP
    awk -v ush="$(cat FULL)" -v hper="$HPER" 'BEGIN { printf "%.0f", ush * hper / 100 }' > HLHP
    if grep -q -o '/dodge/' "$TMP/SRC"; then
      printf "Em batalha clandmg - HP: %s\n" "`cat HP`"
    else
      echo 1 > BREAK_LOOP
      printf "Battle is over!\n"
      sleep 2s
    fi
  }

  cf_access
  : > BREAK_LOOP
  cat HP > old_HP
  echo $(($(date +%s) - 20)) > last_dodge
  echo $(($(date +%s) - 90)) > last_heal
  echo $(($(date +%s) - LA)) > last_atk

  until [ -s "BREAK_LOOP" ]; do
    cf_access
    if ! grep -q -o 'txt smpl grey' "$TMP/SRC" && \
       [ "$(($(date +%s) - $(cat last_dodge)))" -gt 20 ] && \
       [ "$(($(date +%s) - $(cat last_dodge)))" -lt 300 ] && \
       awk -v ush="$(cat HP)" -v oldhp="$(cat old_HP)" 'BEGIN { exit !(ush < oldhp) }'; then
      (
        run_curl "${URL}$(cat DODGE)" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cf_access
      cat HP > old_HP
      date +%s > last_dodge

    elif awk -v ush="$(cat HP)" -v hlhp="$(cat HLHP)" 'BEGIN { exit !(ush < hlhp) }' && \
         [ "$(($(date +%s) - $(cat last_heal)))" -gt 90 ] && \
         [ "$(($(date +%s) - $(cat last_heal)))" -lt 300 ]; then
      (
        run_curl "${URL}$(cat HEAL)" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      sleep 0.3s
      (
        run_curl "${URL}$(cat GRASS)" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cf_access
      cat HP > FULL
      cat HP > old_HP
      date +%s > last_heal

    elif awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && \
         ! grep -q -o 'txt smpl grey' "$TMP/SRC" && \
         awk -v rhp="$(cat RHP)" -v enh="$(cat HP2)" 'BEGIN { exit !(rhp < enh) }' || \
         awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && \
         ! grep -q -o 'txt smpl grey' "$TMP/SRC" && \
         grep -q -o "$(cat CLAN)" "$TMP/callies.txt"; then
      (
        run_curl "${URL}$(cat ATKRND)" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cf_access
      date +%s > last_atk
      sleep 0.3s

    elif awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk > atktime) }'; then
      (
        run_curl "${URL}$(cat ATK)" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cf_access
      date +%s > last_atk
    else
      (
        run_curl "${URL}/clandmgfight" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cf_access
      sleep 1s
    fi
  done

  unset cf_access _random
  func_unset
  printf "Clan duel ok\n"
  clear
}

clandmgfight_start() {
  cd "$TMP" || exit
  apply_event clandmgfight
  case `date +%H:%M` in
  09:2[5-9]|21:2[5-9])
    (
      run_curl "$URL/train" | grep -o -E '\(([0-9]+)\)' | sed 's/[()]//g' > "$TMP/FULL"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
    (
      run_curl "$URL/clandmgfight/?close=reward" > "$TMP/SRC"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
    (
      run_curl "$URL/clandmgfight/enterFight" > "$TMP/SRC"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
    printf "The clan duel will be started...\n"
    while (case `date +%M:%S` in (29:[3-5][0-9]) exit 1;; ([4-5][5-9]:[0-5][0-9]) return;; esac); do
      sleep 3
    done
    (
      run_curl "$URL/clandmgfight/enterFight" > "$TMP/SRC"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
    grep -o -E '(/[a-z]+(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP/SRC" | sed -n '1p' > "$TMP/ACCESS" 2>/dev/null
    printf " Entering...\n"
    printf " Waiting...\n"
    BREAK=$(($(date +%s) + 60))
    until grep -q -o 'clandmgfight/dodge/' "$TMP/ACCESS" || [ "$(date +%s)" -gt "$BREAK" ]; do
      printf " ...\n%s\n" "`cat "$TMP/ACCESS"`"
      (
        run_curl "${URL}/clandmgfight/" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      grep -o -E '(/clandmgfight(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP/SRC" | sed -n '1p' > "$TMP/ACCESS" 2>/dev/null
      sleep 3
    done
    clandmgfight_fight
    sleep 10s
    fetch_page /clandmgfight/enterFight
    clandmgfight_start
    ;;
  09:[3-4][0-9]|21:[3-4][0-9])
    printf "The clan duel will be started...\n"
    (
      run_curl "$URL/clandmgfight/enterFight" > "$TMP/SRC"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
    grep -o -E '(/[a-z]+(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP/SRC" | sed -n '1p' > "$TMP/ACCESS" 2>/dev/null
    printf " Entering...\n"
    printf " Waiting...\n"
    BREAK=$(($(date +%s) + 60))
    until grep -q -o 'clandmgfight/dodge/' "$TMP/ACCESS" || [ "$(date +%s)" -gt "$BREAK" ]; do
      printf " ...\n%s\n" "`cat "$TMP/ACCESS"`"
      (
        run_curl "${URL}/clandmgfight/" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      grep -o -E '(/clandmgfight(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP/SRC" | sed -n '1p' > "$TMP/ACCESS" 2>/dev/null
      sleep 3
    done
    clandmgfight_fight
    sleep 10s
    fetch_page /clandmgfight/enterFight
    clandmgfight_start
    ;;
  esac
}
