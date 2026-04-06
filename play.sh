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
YELLOW='\033[1;33m'
RESET='\033[00m'

mkdir -p "$STATUS_DIR"

chmod +x "$TWMDIR/worker.sh" "$TWMDIR/twm.sh" 2>/dev/null

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

total=`grep -cE '^[^#|]' "$ACCOUNTS_FILE" 2>/dev/null || echo 0`
printf "${CYAN}TWM Multi-contas — %s conta(s)${RESET}\n\n" "$total"

n=0

# Le accounts.conf linha por linha sem redirecionar stdin do shell principal
while IFS='|' read -r srv user encoded <&3; do
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

    # userAgent
    [ ! -f "$acc_dir/userAgent.txt" ] && [ -f "$TWMDIR/userAgent.txt" ] && \
        cp "$TWMDIR/userAgent.txt" "$acc_dir/userAgent.txt"

    printf "${GOLD}[%d/%d]${RESET} [%s] %s\n" "$n" "$total" "$tag" "$user"

    # Para worker anterior desta conta se ainda estiver rodando
    if [ -f "$pid_file" ]; then
        old_pid=`cat "$pid_file"`
        kill -0 "$old_pid" 2>/dev/null && kill -9 "$old_pid" 2>/dev/null
    fi

    echo "starting" > "$status_file"

    # Lanca worker.sh completamente desanexado:
    # - nohup: ignora SIGHUP quando o terminal fechar
    # - < /dev/null: stdin isolado (nao herda o fd3 do loop)
    # - worker.sh salva seu proprio PID com $$
    nohup sh "$TWMDIR/worker.sh" \
        "$srv" "$user" "$encoded" "$tag" \
        "https://$url" "$acc_dir" "$status_file" "$RUN" \
        < /dev/null >> "$log_file" 2>&1 &

    # Aguarda o worker.sh gravar seu PID
    sleep 2
    pid=`cat "$pid_file" 2>/dev/null`
    printf "   PID: %s | Log: %s\n" "${pid:-?}" "$log_file"

done 3< "$ACCOUNTS_FILE"

printf "\n${GREEN}%s worker(s) iniciado(s).${RESET}\n\n" "$n"
printf "Acompanhar conta:  ${CYAN}tail -f ~/.twm/BR_Sherman/twm.log${RESET}\n"
printf "Parar tudo:        ${CYAN}./stop.sh${RESET}\n\n"

# Monitor de status — usa fd3 para nao conflitar com stdin
printf "${CYAN}Monitor (Ctrl+C para sair):${RESET}\n"
while true; do
    sleep 20
    printf "\n--- %s ---\n" "`date +%H:%M:%S`"

    while IFS='|' read -r srv user _enc <&3; do
        case "$srv" in ''|\#*) continue ;; esac
        tag=`server_tag "$srv"`
        acc_id="${tag}_${user}"
        status_file="$STATUS_DIR/${acc_id}.status"
        pid_file="$STATUS_DIR/${acc_id}.pid"
        status=`cat "$status_file" 2>/dev/null || echo "?"`
        pid=`cat "$pid_file" 2>/dev/null`

        if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
            echo "dead" > "$status_file"
            status="dead"
        fi

        case "$status" in
            running)      printf "  ${GREEN}●${RESET} [%s] %s\n" "$tag" "$user" ;;
            login_retry)  printf "  ${YELLOW}↺${RESET} [%s] %s — tentando login\n" "$tag" "$user" ;;
            restarting)   printf "  ${YELLOW}↻${RESET} [%s] %s — reiniciando\n" "$tag" "$user" ;;
            starting)     printf "  ${YELLOW}…${RESET} [%s] %s — iniciando\n" "$tag" "$user" ;;
            dead)         printf "  ${RED}✖${RESET} [%s] %s — MORTO\n" "$tag" "$user" ;;
            *)            printf "  ${GOLD}?${RESET} [%s] %s — %s\n" "$tag" "$user" "$status" ;;
        esac

    done 3< "$ACCOUNTS_FILE"
done
