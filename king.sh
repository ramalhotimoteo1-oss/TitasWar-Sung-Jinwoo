# shellcheck disable=SC2148
king_fight() {
  cd "$TMP" || exit
  LA=4
  HPER="38"
  RPER=5

  cl_access() {
    grep -o -E '(/king/attack/[?]r[=][0-9]+)' "$TMP/SRC" | sed -n 1p > ATK 2>/dev/null
    grep -o -E '(/king/kingatk/[?]r[=][0-9]+)' "$TMP/SRC" | sed -n 1p > KINGATK 2>/dev/null
    grep -o -E '(/king/at[a-z]{0,3}k[a-z]{3,6}/[?]r[=][0-9]+)' "$TMP/SRC" > ATKRND 2>/dev/null
    grep -o -E '(/king/dodge/[?]r[=][0-9]+)' "$TMP/SRC" > DODGE 2>/dev/null
    grep -o -E '(/king/stone/[?]r[=][0-9]+)' "$TMP/SRC" > STONE 2>/dev/null
    grep -o -E '(/king/heal/[?]r[=][0-9]+)' "$TMP/SRC" > HEAL 2>/dev/null
    grep -o -E '([[:upper:]][[:lower:]]{0,15}( [[:upper:]][[:lower:]]{0,13})?)[[:space:]][^[:alnum:][:space:]]' "$TMP/SRC" | sed -n 's,\ [<]s,,;s,\ ,_,;2p' > USER 2>/dev/null
    grep -o -E "(hp)[^A-Za-z0-9_]{1,4}[0-9]{1,6}" "$TMP/SRC" | sed "s,hp[']\\/[>],,;s,\ ,," > HP 2>/dev/null
    grep -o -E "(nbsp)[^A-Za-z0-9_]{1,2}[0-9]{1,6}" "$TMP/SRC" | sed -n 's,nbsp[;],,;s,\ ,,;1p' > HP2 2>/dev/null
    RHP=`awk -v ush="$(cat HP)" -v rper="$RPER" 'BEGIN { printf "%.0f", ush * rper / 100 + ush }'`
    HLHP=`awk -v ush="$(cat FULL)" -v hper="$HPER" 'BEGIN { printf "%.0f", ush * hper / 100 }'`
    if grep -q -o '/dodge/' "$TMP/SRC"; then
      printf "Em batalha - HP: %s\n" "`cat HP`"
    else
      (
        run_curl "${URL}/king" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      grep -o -E '(/king/unrip/[^A-Za-z0-9_]r[^A-Za-z0-9_][0-9]+)' "$TMP/SRC" > UNRIP 2>/dev/null
      if grep -q -o -E '(/king/unrip/[^A-Za-z0-9_]r[^A-Za-z0-9_][0-9]+)' "$TMP/SRC"; then
        (
          run_curl "${URL}$(cat UNRIP)" > "$TMP/SRC"
        ) </dev/null > /dev/null 2>&1 &
        time_exit 17
      else
        echo 1 > BREAK_LOOP
        printf "Battle over.\n"
        sleep 3s
      fi
    fi
  }

  cl_access
  cat HP > old_HP
  echo $(($(date +%s) - 20)) > last_dodge
  echo $(($(date +%s) - 90)) > last_heal
  echo $(($(date +%s) - LA)) > last_atk
  : > BREAK_LOOP

  until [ -s "BREAK_LOOP" ]; do
    : > BREAK_LOOP
    if ! grep -q -o 'txt smpl grey' "$TMP/SRC" && \
       [ "$(($(date +%s) - $(cat last_dodge)))" -gt 20 ] && \
       [ "$(($(date +%s) - $(cat last_dodge)))" -lt 300 ] && \
       awk -v ush="$(cat HP)" -v oldhp="$(cat old_HP)" 'BEGIN { exit !(ush < oldhp) }'; then
      (
        run_curl "${URL}$(cat DODGE)" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cl_access
      cat HP > old_HP; date +%s > last_dodge

    elif awk -v ush="$(cat HP)" -v hlhp="$HLHP" 'BEGIN { exit !(ush < hlhp) }' && \
         [ "$(($(date +%s) - $(cat last_heal)))" -gt 90 ] && \
         [ "$(($(date +%s) - $(cat last_heal)))" -lt 300 ]; then
      (
        run_curl "${URL}$(cat HEAL)" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cl_access
      cat HP > FULL; date +%s > last_heal
      sleep 0.3s

    elif awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk > atktime) }'; then
      if grep -q -o -E '(king/kingatk/[^A-Za-z0-9_]r[^A-Za-z0-9_][0-9]+)' "$TMP/SRC"; then
        (
          run_curl "${URL}$(cat KINGATK)" > "$TMP/SRC"
        ) </dev/null > /dev/null 2>&1 &
        time_exit 17
        cl_access
        if awk -v ush="$(cat HP2)" 'BEGIN { exit !(ush < 25) }'; then
          (
            run_curl "${URL}$(cat STONE)" > "$TMP/SRC"
          ) </dev/null > /dev/null 2>&1 &
          time_exit 17
          cl_access
        fi
      else
        if awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && \
           ! grep -q -o 'txt smpl grey' "$TMP/SRC" && \
           awk -v rhp="$RHP" -v enh="$(cat HP2)" 'BEGIN { exit !(rhp < enh) }' || \
           awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk != atktime) }' && \
           ! grep -q -o 'txt smpl grey' "$TMP/SRC" && \
           grep -q -o "$(cat USER)" allies.txt; then
          (
            run_curl "${URL}$(cat ATKRND)" > "$TMP/SRC"
          ) </dev/null > /dev/null 2>&1 &
          time_exit 17
          cl_access
          date +%s > last_atk
        fi
        (
          run_curl "${URL}$(cat ATK)" > "$TMP/SRC"
        ) </dev/null > /dev/null 2>&1 &
        time_exit 17
        cl_access
      fi
      date +%s > last_atk
    else
      (
        run_curl "${URL}/king" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cl_access
      sleep 1s
    fi
  done

  unset cl_access
  func_unset
  apply_event
  printf "King ok\n"
  sleep 10s
  clear
}

king_start() {
  case `date +%H:%M` in
  (12:2[5-9]|16:2[5-9]|22:2[5-9])
    (
      run_curl "$URL/train" | grep -o -E '\(([0-9]+)\)' | sed 's/[()]//g' > "$TMP/FULL"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
    (
      run_curl "$URL/king/enterGame" > "$TMP/SRC"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
    printf "King of the Immortals will be started...\n"
    until (case `date +%M` in (2[5-9]) exit 1;; esac); do
      sleep 3
    done
    (
      run_curl "$URL/king/enterGame" > "$TMP/SRC"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
    printf "\nKing\n%s\n" "$URL"
    grep -o -E '(/[a-z]+(/[a-z]+/[^A-Za-z0-9]r[^A-Za-z0-9][0-9]+|/))' "$TMP/SRC" | sed -n '1p' > "$TMP/ACCESS" 2>/dev/null
    printf " Entering...\n%s\n" "`cat "$TMP/ACCESS"`"
    printf " Waiting...\n"
    cat "$TMP/SRC" | grep -o 'king/kingatk/' > "$TMP/EXIT" 2>/dev/null
    BREAK=$(($(date +%s) + 30))
    until [ -s "$TMP/EXIT" ] || [ "$(date +%s)" -gt "$BREAK" ]; do
      printf " ...\n%s\n" "`cat "$TMP/ACCESS"`"
      (
        run_curl "${URL}$(cat "$TMP/ACCESS")" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cat "$TMP/SRC" | sed 's/href=/\n/g' | grep '/king/' | head -n 1 | awk -F"[']" '{ print $2 }' > "$TMP/ACCESS" 2>/dev/null
      cat "$TMP/SRC" | grep -o 'king/kingatk/' > "$TMP/EXIT" 2>/dev/null
      sleep 2
    done
    king_fight
    ;;
  esac
}
