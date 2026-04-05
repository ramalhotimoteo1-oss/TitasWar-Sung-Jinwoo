#!/bin/sh
# play.sh - Orquestrador multi-contas TWM

_dir=`dirname "$0"`
TWMDIR=`cd "$_dir" && pwd`
unset _dir
export TWMDIR

ACCOUNTS_FILE="$TWMDIR/accounts.conf"
STATUS_DIR="$HOME/.twm/status"
RUN="${1:--boot}"

# Cores
GREEN='\033[32m'
GOLD='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[01;36m'
RESET='\033[00m'

mkdir -p "$STATUS_DIR"

# Mapa de servidores
server_url() {
    case "$1" in
        1)  echo "furiadetitas.net" ;;
        2)  echo "titanen.mobi" ;;
        3)  echo "guerradetitanes.net" ;;
        4)  echo "tiwar.fr" ;;
        5)  echo "in.tiwar.net" ;;
        6)  echo "tiwar-id.net" ;;
        7)  echo "guerraditiani.net" ;;
        8)  echo "tiwar.pl" ;;
        9)  echo "tiwar.ro" ;;
        10) echo "tiwar.ru" ;;
        11) echo "rs.tiwar.net" ;;
        12) echo "cn.tiwar.net" ;;
        13) echo "tiwar.net" ;;
    esac
}

server_tag() {
    case "$1" in
        1)  echo "BR" ;;
        2)  echo "DE" ;;
        3)  echo "ES" ;;
        4)  echo "FR" ;;
        5)  echo "IN" ;;
        6)  echo "ID" ;;
        7)  echo "IT" ;;
        8)  echo "PL" ;;
        9)  echo "RO" ;;
        10) echo "RU" ;;
        11) echo "SR" ;;
        12) echo "ZH" ;;
        13) echo "EN" ;;
    esac
}

# Verifica se accounts.conf existe e tem contas
if [ ! -f "$ACCOUNTS_FILE" ] || [ ! -s "$ACCOUNTS_FILE" ]; then
    printf "${RED}Nenhuma conta cadastrada.${RESET}\n"
    printf "Execute primeiro: ${GOLD}./setup.sh${RESET}\n"
    exit 1
fi

# Conta total de contas
total=`grep -c '' "$ACCOUNTS_FILE" 2>/dev/null || echo 0`
printf "${CYAN}TWM Multi-contas — %s conta(s) encontrada(s)${RESET}\n\n" "$total"

# Lanca um worker por conta
n=0
while IFS='|' read -r srv user encoded; do
    # Ignora linhas vazias ou comentarios
    case "$srv" in
        ''|\#*) continue ;;
    esac

    n=$((n + 1))
    url=`server_url "$srv"`
    tag=`server_tag "$srv"`
    acc_id="${tag}_${user}"
    acc_dir="$HOME/.twm/${acc_id}"
    status_file="$STATUS_DIR/${acc_id}.status"

    mkdir -p "$acc_dir"

    # Prepara credencial para o worker
    cript_file="$acc_dir/cript_file"
    echo "$encoded" > "$cript_file"
    chmod 600 "$cript_file"

    # Prepara userAgent se nao existir
    if [ ! -f "$acc_dir/userAgent.txt" ] && [ -f "$TWMDIR/userAgent.txt" ]; then
        cp "$TWMDIR/userAgent.txt" "$acc_dir/userAgent.txt"
    fi

    printf "${GOLD}[%d/%d]${RESET} Iniciando [%s] %s em https://%s\n" "$n" "$total" "$tag" "$user" "$url"

    # Marca status inicial
    echo "starting" > "$status_file"

    # Lanca worker em background com variaveis da conta injetadas
    (
        # Injeta variaveis da conta diretamente no ambiente do worker
        export TWM_SRV="$srv"
        export TWM_URL="https://$url"
        export TWM_USER="$user"
        export TWM_TAG="$tag"
        export TWM_ACC_DIR="$acc_dir"
        export TWM_STATUS_FILE="$status_file"

        while true; do
            echo "running" > "$status_file"
            sh "$TWMDIR/twm.sh" "$RUN"
            exit_code=$?

            if [ "$exit_code" -ne 0 ]; then
                echo "failed" > "$status_file"
                printf "${RED}[%s] %s — falhou (exit %s). Marcando como erro.${RESET}\n" \
                    "$tag" "$user" "$exit_code"
                # Nao reinicia — marca falha e encerra este worker
                break
            fi

            # twm.sh encerrou normalmente (improvavel em modo boot) — reinicia
            sleep 5
        done
    ) >> "$acc_dir/twm.log" 2>&1 &

    # Guarda PID do worker
    echo $! > "$STATUS_DIR/${acc_id}.pid"

    # Pequeno delay entre lancamentos para nao sobrecarregar
    sleep 2

done < "$ACCOUNTS_FILE"

if [ "$n" -eq 0 ]; then
    printf "${RED}Nenhuma conta valida encontrada em accounts.conf.${RESET}\n"
    exit 1
fi

printf "\n${GREEN}%s worker(s) iniciado(s).${RESET}\n" "$n"
printf "Logs em: ${GOLD}~/.twm/<TAG>_<CONTA>/twm.log${RESET}\n"
printf "Status:  ${GOLD}~/.twm/status/<TAG>_<CONTA>.status${RESET}\n\n"
printf "Para acompanhar uma conta:\n"
printf "  ${CYAN}tail -f ~/.twm/BR_NomeConta/twm.log${RESET}\n\n"
printf "Para parar tudo:\n"
printf "  ${CYAN}./stop.sh${RESET}\n\n"

# Monitora status das contas em loop
printf "${CYAN}Status das contas (Ctrl+C para sair do monitor):${RESET}\n"
while true; do
    sleep 30
    printf "\n--- %s ---\n" "`date +%H:%M:%S`"
    while IFS='|' read -r srv user _enc; do
        case "$srv" in ''|\#*) continue ;; esac
        tag=`server_tag "$srv"`
        acc_id="${tag}_${user}"
        status_file="$STATUS_DIR/${acc_id}.status"
        pid_file="$STATUS_DIR/${acc_id}.pid"
        status=`cat "$status_file" 2>/dev/null || echo "unknown"`
        pid=`cat "$pid_file" 2>/dev/null`

        # Verifica se o processo ainda esta rodando
        if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
            status="dead"
            echo "dead" > "$status_file"
        fi

        case "$status" in
            running) color="$GREEN" ;;
            failed|dead) color="$RED" ;;
            *) color="$GOLD" ;;
        esac

        printf "  ${color}[%s] %s — %s${RESET}\n" "$tag" "$user" "$status"
    done < "$ACCOUNTS_FILE"
done
