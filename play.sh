#!/bin/sh

# Detecta o diretorio real onde play.sh esta instalado
# Sem aninhamento de $() dentro de crases — compativel com sh do Termux
_twm_script="$0"
_twm_dir=`dirname "$_twm_script"`
TWMDIR=`cd "$_twm_dir" && pwd`
export TWMDIR
unset _twm_script _twm_dir

# Debug: mostra o diretorio detectado na primeira execucao
printf "TWMDIR: %s\n" "$TWMDIR"

RUN=$1

# Garante que o diretorio existe
mkdir -p "$TWMDIR"

while true; do
    # Mata processos twm.sh anteriores vinculados a este diretorio
    pidf=`ps ax -o pid=,args= 2>/dev/null | grep "twm.sh" | grep "$TWMDIR" | grep -v grep | head -n 1 | grep -o -E '[0-9]{3,6}' | head -n 1`

    until [ -z "$pidf" ]; do
        kill -9 "$pidf" 2>/dev/null
        pidf=`ps ax -o pid=,args= 2>/dev/null | grep "twm.sh" | grep "$TWMDIR" | grep -v grep | head -n 1 | grep -o -E '[0-9]{3,6}' | head -n 1`
        sleep 1s
    done

    run_mode() {
        chmod +x "$TWMDIR/twm.sh" 2>/dev/null

        if echo "$RUN" | grep -q -E '[-]cl'; then
            echo '-cl' > "$TWMDIR/runmode_file"
            sh "$TWMDIR/twm.sh" -cl
        elif echo "$RUN" | grep -q -E '[-]cv'; then
            echo '-cv' > "$TWMDIR/runmode_file"
            sh "$TWMDIR/twm.sh" -cv
        elif echo "$RUN" | grep -q -E '[-]boot'; then
            echo '-boot' > "$TWMDIR/runmode_file"
            sh "$TWMDIR/twm.sh" -boot
        else
            echo '-boot' > "$TWMDIR/runmode_file"
            sh "$TWMDIR/twm.sh" -boot
        fi
    }

    run_mode
    sleep 0.1s
done
