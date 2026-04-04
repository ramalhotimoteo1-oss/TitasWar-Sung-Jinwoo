#!/bin/sh

# play.sh - gerencia execucao do twm.sh com isolamento de conta por TMP
(
  RUN=$1

  while true; do
    # Mata apenas processos do twm.sh vinculados ao diretorio desta conta
    # A conta e identificada pelo TMP que sera exportado pelo twm.sh
    pidf=`ps ax -o pid=,args= | grep "sh.*twm/twm.sh" | grep -v grep | head -n 1 | grep -o -E '([0-9]{3,6})'`

    until [ -z "${pidf}" ]; do
      kill -9 ${pidf} 2>/dev/null
      pidf=`ps ax -o pid=,args= | grep "sh.*twm/twm.sh" | grep -v grep | head -n 1 | grep -o -E '([0-9]{3,6})'`
      sleep 1s
    done

    run_mode() {
      chmod +x "$HOME/twm/twm.sh"

      if echo "$RUN" | grep -q -E '[-]cl'; then
        echo '-cl' > "$HOME/twm/runmode_file"
        "$HOME"/twm/twm.sh -cl
      elif echo "$RUN" | grep -q -E '[-]cv'; then
        echo '-cv' > "$HOME/twm/runmode_file"
        "$HOME"/twm/twm.sh -cv
      elif echo "$RUN" | grep -q -E '[-]boot'; then
        echo '-boot' > "$HOME/twm/runmode_file"
        "$HOME"/twm/twm.sh -boot
      else
        echo '-boot' > "$HOME/twm/runmode_file"
        "$HOME"/twm/twm.sh -boot
      fi
    }

    run_mode
    sleep 0.1s
  done
)
