#!/bin/sh
# stop.sh - Para todos os workers do TWM Multi-contas

_dir=`dirname "$0"`
TWMDIR=`cd "$_dir" && pwd`
unset _dir

STATUS_DIR="$HOME/.twm/status"

GREEN='\033[32m'
RED='\033[0;31m'
GOLD='\033[0;33m'
RESET='\033[00m'

printf "${GOLD}Parando todos os workers TWM...${RESET}\n\n"

stopped=0
failed=0

for pid_file in "$STATUS_DIR"/*.pid; do
    [ -f "$pid_file" ] || continue

    acc_id=`basename "$pid_file" .pid`
    pid=`cat "$pid_file"`

    if kill -0 "$pid" 2>/dev/null; then
        kill -15 "$pid" 2>/dev/null
        sleep 1
        # Forca se ainda estiver rodando
        kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
        echo "stopped" > "$STATUS_DIR/${acc_id}.status"
        printf "  ${GREEN}[OK]${RESET} %s (PID %s)\n" "$acc_id" "$pid"
        stopped=$((stopped + 1))
    else
        printf "  ${GOLD}[JA PARADO]${RESET} %s\n" "$acc_id"
    fi

    rm -f "$pid_file"
done

# Mata qualquer twm.sh residual
pkill -f "twm.sh" 2>/dev/null

printf "\n${GREEN}%s worker(s) encerrado(s).${RESET}\n" "$stopped"
termux-wake-unlock 2>/dev/null
