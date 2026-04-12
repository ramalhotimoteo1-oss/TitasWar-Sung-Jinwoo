#!/data/data/com.termux/files/home/.multcf/toybox bash# Fallback: se nao estiver rodando com toybox, reexecuta com ele                                            TOYBOX="$HOME/.multcf/toybox"                         if [ -x "$TOYBOX" ] && [ -z "$_TOYBOX_RUNNING" ]; then    _TOYBOX_RUNNING=1 exec "$TOYBOX" bash "$0" "$@"   fi                                                    export TOYBOX                                                                                               _dir=$(dirname "$0")                                  TWMDIR=$(cd "$_dir" && pwd)
unset _dir
export TWMDIR                                         
ACCOUNTS_FILE="$TWMDIR/accounts.conf"
                                                      # Mantem o Termux acordado enquanto o monitor roda
termux-wake-lock 2>/dev/null
STATUS_DIR="$HOME/.twm/status"                        RUN="${1:--boot}"

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

total=$(grep -cE '^[^#|]' "$ACCOUNTS_FILE" 2>/dev/null || echo 0)
printf "${CYAN}TWM Multi-contas — %s conta(s) ${RESET}\n\n" "$total"

n=0

# Le accounts.conf via fd3 — nao redireciona stdin do shell principal
while IFS='|' read -r srv user encoded <&3; do
    case "$srv" in ''|\#*) continue ;; esac

    n=$((n + 1))
    url=$(server_url "$srv")
    tag=$(server_tag "$srv")
    acc_id="${tag}_${user}"
    acc_dir="$HOME/.twm/${acc_id}"
    status_file="$STATUS_DIR/${acc_id}.status"
    pid_file="$STATUS_DIR/${acc_id}.pid"
    log_file="$acc_dir/twm.log"

    mkdir -p "$acc_dir"

    [ ! -f "$acc_dir/userAgent.txt" ] && [ -f "$TWMDIR/userAgent.txt" ] && \
        cp "$TWMDIR/userAgent.txt" "$acc_dir/userAgent.txt"

    printf "${GOLD}[%d/%d]${RESET} [%s] %s\n" "$n" "$total" "$tag" "$user"

    # Para worker anterior se ainda estiver rodando
    if [ -f "$pid_file" ]; then
        old_pid=$(cat "$pid_file")
        kill -0 "$old_pid" 2>/dev/null && kill -9 "$old_pid" 2>/dev/null
    fi

    echo "starting" > "$status_file"

    # Lanca worker completamente desanexado com toybox
    TOYBOX="$TOYBOX" _TOYBOX_RUNNING="" \
    nohup "$TOYBOX" bash "$TWMDIR/worker.sh" \
        "$srv" "$user" "$encoded" "$tag" \
        "https://$url" "$acc_dir" "$status_file" "$RUN" \
        < /dev/null >> "$log_file" 2>&1 &

    # Aguarda PID com retry — ate 10s
    pid=""
    _w=0
    while [ -z "$pid" ] && [ $_w -lt 10 ]; do
        sleep 1
        pid=$(cat "$pid_file" 2>/dev/null)
        _w=$((_w + 1))
    done
    printf "   PID: %s | Log: %s\n" "${pid:-FALHOU}" "$log_file"
    if [ -z "$pid" ]; then
        printf "   AVISO: worker nao iniciou. Verifique %s\n" "$log_file"
    fi

done 3< "$ACCOUNTS_FILE"

printf "\n${GREEN}%s worker(s) iniciado(s).${RESET}\n\n" "$n"
printf "Acompanhar conta:  ${CYAN}tail -f ~/.twm/BR_Sherman/twm.log${RESET}\n"
printf "Parar tudo:        ${CYAN}./stop.sh${RESET}\n\n"

# Monitor de status
W="======================================"

while true; do
    clear
    now=$(date +%H:%M:%S)

    printf "╔%s╗\n" "$W"
    printf "║  TWM Multi-contas        %s  ║\n" "$now"
    printf "╠%s╣\n" "$W"

    while IFS='|' read -r srv user _enc <&3; do
        case "$srv" in ''|\#*) continue ;; esac
        tag=$(server_tag "$srv")
        acc_id="${tag}_${user}"
        status_file="$STATUS_DIR/${acc_id}.status"
        pid_file="$STATUS_DIR/${acc_id}.pid"
        status=$(cat "$status_file" 2>/dev/null || echo "?")
        pid=$(cat "$pid_file" 2>/dev/null)

        if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
            echo "dead" > "$status_file"
            status="dead"
        fi

        case "$status" in
            running)     col="\033[32m" label="online"      ;;
            loading)     col="\033[33m" label="carregando"  ;;
            login_retry) col="\033[33m" label="login..."    ;;
            restarting)  col="\033[33m" label="reiniciando" ;;
            starting)    col="\033[33m" label="iniciando"   ;;
            dead)        col="\033[31m" label="ERRO"        ;;
            *)           col="\033[33m" label="$status"     ;;
        esac

        entry=$(printf "[%s] %-16s %-10s" "$tag" "$user" "$label")
        printf "║  %b* %s\033[00m  ║\n" "$col" "$entry"

    done 3< "$ACCOUNTS_FILE"

    printf "╚%s╝\n" "$W"

    _i=0
    while [ $_i -lt 20 ]; do
        sleep 1
        _i=$((_i + 1))
    done
done
