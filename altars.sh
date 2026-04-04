altars_fight() {
  cd "$TMP" || exit
  apply_event

  LA=4
  echo "48" > HPER
  echo "15" > RPER

  cf_access() {
    grep -o -E '(/[a-z]+/[a-z]{0,4}at[a-z]{0,3}k/[?]r[=][0-9]+)' "$TMP/src.html" | sed -n 1p > ATK 2>/dev/null
    grep -o -E '(/[a-z]+/at[a-z]{0,3}k[a-z]{3,6}/[?]r[=][0-9]+)' "$TMP/src.html" > ATKRND 2>/dev/null
    grep -o -E '(/altars/dodge/[?]r[=][0-9]+)' "$TMP/src.html" > DODGE 2>/dev/null
    grep -o -E '(/altars/heal/[?]r[=][0-9]+)' "$TMP/src.html" > HEAL 2>/dev/null
    grep -o -E '([[:upper:]][[:lower:]]{0,20}( [[:upper:]][[:lower:]]{0,17})?)[[:space:]]\(' "$TMP/src.html" | sed -n 's,\ [(],,;s,\ ,_,;2p' > CLAN 2>/dev/null
    grep -o -E "(hp)[^A-Za-z0-9]{1,4}[0-9]{1,6}" "$TMP/src.html" | sed "s,hp[']\\/[>],,;s,\ ,," > HP 2>/dev/null
    grep -o -E "(nbsp)[^A-Za-z0-9]{1,2}[0-9]{1,6}" "$TMP/src.html" | sed -n 's,nbsp[;],,;s,\ ,,;1p' > HP2 2>/dev/null
    awk -v ush="$(cat HP)" -v rper="$(cat RPER)" 'BEGIN { printf "%.0f", ush * rper / 100 + ush }' > RHP
    awk -v ush="$(cat FULL)" -v hper="$(cat HPER)" 'BEGIN { printf "%.0f", ush * hper / 100 }' > HLHP
    if grep -q -o '/dodge/' "$TMP/src.html"; then
      printf "Em batalha - HP: %s\n" "`cat HP`"
    else
      echo 1 > BREAK_LOOP
      printf "Battle over!\n"
      sleep 2s
    fi
  }

  cf_access
  : > BREAK_LOOP; cat HP > old_HP
  echo $(($(date +%s) - 20)) > last_dodge
  echo $(($(date +%s) - 90)) > last_heal
  echo $(($(date +%s) - LA)) > last_atk

  until [ -s "BREAK_LOOP" ]; do
    cf_access
    if ! grep -q -o 'txt smpl grey' "$TMP/src.html" && \
       [ "$(($(date +%s) - $(cat last_dodge)))" -gt 20 ] && \
       [ "$(($(date +%s) - $(cat last_dodge)))" -lt 300 ] && \
       awk -v ush="$(cat HP)" -v oldhp="$(cat old_HP)" 'BEGIN { exit !(ush < oldhp) }'; then
      (
        run_curl "${URL}$(cat DODGE)" > "$TMP/src.html"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cf_access
      cat HP > old_HP; date +%s > last_dodge

    elif awk -v ush="$(cat HP)" -v hlhp="$(cat HLHP)" 'BEGIN { exit !(ush < hlhp) }' && \
         [ "$(($(date +%s) - $(cat last_heal)))" -gt 90 ] && \
         [ "$(($(date +%s) - $(cat last_heal)))" -lt 300 ]; then
      (
        run_curl "${URL}$(cat HEAL)" > "$TMP/src.html"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cf_access
      cat HP > FULL; cat HP > old_HP
      date +%s > last_heal

    elif awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && \
         ! grep -q -o 'txt smpl grey' "$TMP/src.html" && \
         awk -v rhp="$(cat RHP)" -v enh="$(cat HP2)" 'BEGIN { exit !(rhp < enh) }' || \
         awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && \
         ! grep -q -o 'txt smpl grey' "$TMP/src.html" && \
         grep -q -o "$(cat CLAN)" "$TMP/callies.txt"; then
      (
        run_curl "${URL}$(cat ATKRND)" > "$TMP/src.html"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cf_access
      date +%s > last_atk

    elif awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk > atktime) }'; then
      (
        run_curl "${URL}$(cat ATK)" > "$TMP/src.html"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cf_access
      date +%s > last_atk
    else
      (
        run_curl "${URL}/altars" > "$TMP/src.html"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cf_access
      sleep 1s
    fi
  done

  unset cf_access _random
  func_unset
  apply_event
  printf "Altars ok\n"
  sleep 10s
  clear
}

altars_start() {
  case `date +%H:%M` in
  (13:5[5-9]|20:5[5-9])
    (
      run_curl "$URL/train" | grep -o -E '\(([0-9]+)\)' | sed 's/[()]//g' > "$TMP/FULL"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17

    fetch_page "/altars/?close=reward" "$TMP/src.html"
    fetch_page "/altars/enterFight" "$TMP/src.html"
    printf "Ancient Altars will be started...\n"

    until (case `date +%M` in (55|56|57|58|59) exit 1;; esac); do
      sleep 2
    done

    fetch_page "/altars/enterFight" "$TMP/src.html"
    printf "Altars will be started...\n"
    grep -o -E '(/altars(/[A-Za-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP/src.html" | sed -n 1p > "$TMP/ACCESS" 2>/dev/null
    printf " Entering...\n"
    printf " Waiting...\n"
    BREAK=$(($(date +%s) + 30))
    until grep -q -o 'altars/dodge/' "$TMP/ACCESS" || [ "$(date +%s)" -gt "$BREAK" ]; do
      printf "%s\n ...\n%s\n" "$URL" "`cat "$TMP/ACCESS"`"
      fetch_page "/altars" "$TMP/src.html"
      grep -o -E '(/altars(/[A-Za-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP/src.html" | sed -n 1p > "$TMP/ACCESS" 2>/dev/null
      sleep 3
    done
    altars_fight
    ;;
  esac
}
