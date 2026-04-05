#!/bin/sh

# Detecta o diretorio real onde play.sh esta instalado
# Funciona independente de onde o script e chamado (./play.sh, ~/dir/play.sh, etc.)
TWMDIR=`cd "$(dirname "$0")" && pwd`
export TWMDIR

RUN=$1

# Garante que o diretorio existe e cria runmode_file se necessario
mkdir -p "$TWMDIR"

while true; do
    # Mata processos twm.sh anteriores deste mesmo diretorio
    pidf=`ps ax -o pid=,args= | grep "sh.*twm.sh" | grep "$TWMDIR" | grep -v grep | head -n 1 | grep -o -E '([0-9]{3,6})'`

    until [ -z "${pidf}" ]; do
        kill -9 ${pidf} 2>/dev/null
        pidf=`ps ax -o pid=,args= | grep "sh.*twm.sh" | grep "$TWMDIR" | grep -v grep | head -n 1 | grep -o -E '([0-9]{3,6})'`
        sleep 1s
    done

    run_mode() {
        chmod +x "$TWMDIR/twm.sh"

        if echo "$RUN" | grep -q -E '[-]cl'; then
            echo '-cl' > "$TWMDIR/runmode_file"
            "$TWMDIR/twm.sh" -cl
        elif echo "$RUN" | grep -q -E '[-]cv'; then
            echo '-cv' > "$TWMDIR/runmode_file"
            "$TWMDIR/twm.sh" -cv
        elif echo "$RUN" | grep -q -E '[-]boot'; then
            echo '-boot' > "$TWMDIR/runmode_file"
            "$TWMDIR/twm.sh" -boot
        else
            echo '-boot' > "$TWMDIR/runmode_file"
            "$TWMDIR/twm.sh" -boot
        fi
    }

    run_mode
    sleep 0.1s
done
