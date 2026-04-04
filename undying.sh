undying_fight() {
  cd "$TMP" || exit
  LA=5

  cf_access() {
    grep -o -E '/undying/(hit|mana)/[?][r][=][0-9]+' "$TMP/SRC" | sed -n '1p' > HITMANA 2>/dev/null

    if grep -q -o 'out_gate' "$TMP/SRC"; then
      printf "Em batalha undying\n"
    else
      echo 1 > BREAK_LOOP
      printf "Battle over!\n"
      sleep 2s
    fi
  }

  cf_access
  > BREAK_LOOP
  echo $(($(date +%s) - LA)) > last_atk

  until [ -s "BREAK_LOOP" ]; do
    cf_access
    if awk -v latk="$(($(date +%s) - $(cat last_atk)))" -v atktime="$LA" 'BEGIN { exit !(latk > atktime) }'; then
      (
        run_curl "${URL}$(cat HITMANA)" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cf_access
      date +%s > last_atk
    else
      (
        run_curl "${URL}/undying" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17
      cf_access
      sleep 1s
    fi
  done

  unset cf_access
  printf "Undying ok\n"
  sleep 15s
  apply_event undying
}

undying_start() {
  cd "$TMP" || exit

  case `date +%H:%M` in
  (09:5[5-9]|15:5[5-9]|21:5[5-9])
    hpmp -fix
    use_elixir
    apply_event undying
    printf "Valley of the Immortals will be started... %s\n" "`date +%Hh:%Mm`"

    until (case `date +%M` in (5[5-9]) exit 1;; esac); do
      sleep 2
    done

    hpmp -now

    if awk -v hpper="$HPPER" 'BEGIN { exit !(hpper > 20) }' && \
       awk -v mpper="$MPPER" 'BEGIN { exit !(mpper > 10) }'; then
      arena_fullmana
    fi

    while awk -v minute="`date +%M`" 'BEGIN { exit !(minute != 00) }' && [ `date +%M` -gt "57" ]; do
      sleep 5s
    done

    (
      run_curl "$URL/undying/" > "$TMP/SRC"
    ) </dev/null > /dev/null 2>&1 &
    time_exit 17
    grep -o -E '/undying/(mana|hit)/[?][r][=][0-9]+' "$TMP/SRC" | head -n 1 > "$TMP/HITMANA" 2>/dev/null

    > BREAK_LOOP
    BREAK=$(($(date +%s) + 11))

    until [ -s "BREAK_LOOP" ] || [ "$(date +%s)" -gt "$BREAK" ]; do
      (
        run_curl "$URL/undying" > "$TMP/SRC"
      ) </dev/null > /dev/null 2>&1 &
      time_exit 17

      grep -o -E '/undying/(mana|hit)/[?][r][=][0-9]+' "$TMP/SRC" | head -n 1 > "$TMP/HITMANA" 2>/dev/null

      if grep -q -o -E '/undying/(hit|mana)' "$TMP/SRC"; then
        (
          run_curl "${URL}$(cat "$TMP/HITMANA")" > "$TMP/SRC"
        ) </dev/null > /dev/null 2>&1 &
        time_exit 17
        echo "1" > BREAK_LOOP
        printf " ... undying iniciado\n"
      fi
      sleep 0.3s
    done

    arena_fullmana
    undying_fight
    ;;
  esac
}
