#!/bin/sh
# play.sh - Orquestrador multi-contas TWM

_dir=`dirname "$0"`
TWMDIR=`cd "$_dir" && pwd`
unset _dir
export TWMDIR

ACCOUNTS_FILE="$TWMDIR/accounts.conf"
STATUS_DIR="$HOME/.twm/status"
RUN="${1:--boot}"

GREEN='\033[32m'
GOLD='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[01;36m'
YELLOW='\033[0;33m'
RESET='\033[00m'

mkdir -p "$STATUS_DIR"

server_url() {
    case "$1" in
        1)  echo "furiadetitas.net" ;;   2)  echo "titanen.mobi" ;;
        3)  echo "guerradetitanes.net" ;; 4)  echo "tiwar.fr" ;;
        5)  echo "in.tiwar.net" ;;        6)  echo "tiwar-id.net" ;;
        7)  echo "guerraditiani.net" ;;   8)  echo "tiwar.pl" ;;
        9)  echo "tiwar.ro" ;;            10) echo "tiwar.ru" ;;
        11) echo "rs.tiwar.net" ;;        12) echo "cn.tiwar.net" ;;
        13) echo "tiwar.net" ;;
    esac
}

server_tag() {
    case "$1" in
        1) echo "BR" ;;  2) echo "DE" ;;  3) echo "ES" ;;
        4) echo "FR" ;;  5) echo "IN" ;;  6) echo "ID" ;;
        7) echo "IT" ;;  8) echo "PL" ;;  9) echo "RO" ;;
        10) echo "RU" ;; 11) echo "SR" ;; 12) echo "ZH" ;;
        13) echo "EN" ;;
    esac
}

if [ ! -f "$ACCOUNTS_FILE" ] || [ ! -s "$ACCOUNTS_FILE" ]; then
    printf "${RED}Nenhuma conta cadastrada.${RESET}\n"
    printf "Execute: ${GOLD}./setup.sh${RESET}\n"
    exit 1
fi

total=`grep -cE '^[^#]' "$ACCOUNTS_FILE" 2>/dev/null || echo 0`
printf "${CYAN}TWM Multi-contas — %s conta(s)${RESET}\n\n" "$total"

n=0
while IFS='|' read -r srv user encoded; do
    case "$srv" in ''|\#*) continue ;; esac

    n=$((n + 1))
    url=`server_url "$srv"`
    tag=`server_tag "$srv"`
    acc_id="${tag}_${user}"
    acc_dir="$HOME/.twm/${acc_id}"
    status_file="$STATUS_DIR/${acc_id}.status"
    pid_file="$STATUS_DIR/${acc_id}.pid"
    log_file="$acc_dir/twm.log"

    mkdir -p "$acc_dir"

    # Credencial
    echo "$encoded" > "$acc_dir/cript_file"
    chmod 600 "$acc_dir/cript_file"

    # userAgent
    [ ! -f "$acc_dir/userAgent.txt" ] && [ -f "$TWMDIR/userAgent.txt" ] && \
        cp "$TWMDIR/userAgent.txt" "$acc_dir/userAgent.txt"

    printf "${GOLD}[%d/%d]${RESET} [%s] %s\n" "$n" "$total" "$tag" "$user"
    echo "starting" > "$status_file"

    # Lanca worker em background
    (
        export TWM_SRV="$srv"
        export TWM_URL="https://$url"
        export TWM_USER="$user"
        export TWM_TAG="$tag"
        export TWM_ACC_DIR="$acc_dir"
        export TWM_STATUS_FILE="$status_file"

        # Worker nunca morre — se twm.sh encerrar inesperadamente, reinicia
        while true; do
            echo "running" > "$status_file"
            sh "$TWMDIR/twm.sh" "$RUN"
            echo "restarting" > "$status_file"
            printf "[%s] %s — reiniciando em 10s\n" "$tag" "$user"
            sleep 10
        done
    ) >> "$log_file" 2>&1 &

    worker_pid=$!
    echo "$worker_pid" > "$pid_file"
    printf "   PID: %s | Log: %s\n" "$worker_pid" "$log_file"
    sleep 1

done < "$ACCOUNTS_FILE"

printf "\n${GREEN}%s worker(s) iniciado(s).${RESET}\n\n" "$n"
printf "Comandos uteis:\n"
printf "  ${CYAN}tail -f ~/.twm/BR_Sherman/twm.log${RESET}   acompanha conta\n"
printf "  ${CYAN}./stop.sh${RESET}                            para tudo\n\n"

# Monitor de status
printf "${CYAN}Monitor (Ctrl+C para sair):${RESET}\n"
while true; do
    sleep 20
    printf "\r"
    line=""
    while IFS='|' read -r srv user _enc; do
        case "$srv" in ''|\#*) continue ;; esac
        tag=`server_tag "$srv"`
        acc_id="${tag}_${user}"
        status_file="$STATUS_DIR/${acc_id}.status"
        pid_file="$STATUS_DIR/${acc_id}.pid"
        status=`cat "$status_file" 2>/dev/null || echo "?"`
        pid=`cat "$pid_file" 2>/dev/null`

        # Verifica se o processo wrapper ainda existe
        if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
            echo "dead" > "$status_file"
            status="dead"
        fi

        case "$status" in
            running)      icon="${GREEN}●${RESET}" ;;
            login_retry)  icon="${YELLOW}↺${RESET}" ;;
            restarting)   icon="${YELLOW}↻${RESET}" ;;
            dead)         icon="${RED}✖${RESET}" ;;
            *)            icon="${GOLD}?${RESET}" ;;
        esac

        printf "  %b [%s] %-15s %s\n" "$icon" "$tag" "$user" "$status"
    done < "$ACCOUNTS_FILE"
done
