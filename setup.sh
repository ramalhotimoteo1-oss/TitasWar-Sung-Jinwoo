#!/bin/sh
# setup.sh - Gerenciamento de contas do TWM Multi-contas

_dir=`dirname "$0"`
TWMDIR=`cd "$_dir" && pwd`
unset _dir

ACCOUNTS_FILE="$TWMDIR/accounts.conf"

# Carrega funcoes de verificacao de sessao
. "$TWMDIR/session_check.sh"

# Cores
GREEN='\033[32m'
GOLD='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[01;36m'
RESET='\033[00m'

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
        1)  echo "BR" ;;  2)  echo "DE" ;;  3)  echo "ES" ;;
        4)  echo "FR" ;;  5)  echo "IN" ;;  6)  echo "ID" ;;
        7)  echo "IT" ;;  8)  echo "PL" ;;  9)  echo "RO" ;;
        10) echo "RU" ;;  11) echo "SR" ;;  12) echo "ZH" ;;
        13) echo "EN" ;;
    esac
}

show_menu() {
    clear
    printf "${CYAN}╔══════════════════════════════════════╗${RESET}\n"
    printf "${CYAN}║     TWM Multi-contas — Setup         ║${RESET}\n"
    printf "${CYAN}╚══════════════════════════════════════╝${RESET}\n\n"
    n=0
    [ -f "$ACCOUNTS_FILE" ] && n=`grep -c '' "$ACCOUNTS_FILE" 2>/dev/null || echo 0`
    printf "Contas cadastradas: ${GOLD}%s${RESET}\n\n" "$n"
    printf "${GOLD}1)${RESET} Listar contas\n"
    printf "${GOLD}2)${RESET} Adicionar conta\n"
    printf "${GOLD}3)${RESET} Remover conta\n"
    printf "${GOLD}4)${RESET} Testar login\n"
    printf "${GOLD}0)${RESET} Sair\n\n"
    printf "Opcao: "
}

list_accounts() {
    clear
    printf "${CYAN}=== Contas cadastradas ===${RESET}\n\n"
    if [ ! -f "$ACCOUNTS_FILE" ] || [ ! -s "$ACCOUNTS_FILE" ]; then
        printf "${RED}Nenhuma conta cadastrada ainda.${RESET}\n"
    else
        n=1
        while IFS='|' read -r srv user _enc; do
            case "$srv" in ''|\#*) continue ;; esac
            url=`server_url "$srv"`
            tag=`server_tag "$srv"`
            printf "${GOLD}%d)${RESET} [%s] %-20s %s\n" "$n" "$tag" "$user" "$url"
            n=$((n + 1))
        done < "$ACCOUNTS_FILE"
    fi
    printf "\nENTER para voltar..."
    read -r _d
}

show_servers() {
    printf "\n${CYAN}Servidores:${RESET}\n"
    printf " 1) BR  furiadetitas.net     2) DE  titanen.mobi\n"
    printf " 3) ES  guerradetitanes.net  4) FR  tiwar.fr\n"
    printf " 5) IN  in.tiwar.net         6) ID  tiwar-id.net\n"
    printf " 7) IT  guerraditiani.net    8) PL  tiwar.pl\n"
    printf " 9) RO  tiwar.ro            10) RU  tiwar.ru\n"
    printf "11) SR  rs.tiwar.net        12) ZH  cn.tiwar.net\n"
    printf "13) EN  tiwar.net\n"
}

add_account() {
    clear
    printf "${CYAN}=== Adicionar conta ===${RESET}\n"
    show_servers
    printf "\nNumero do servidor: "
    read -r srv

    case "$srv" in
        [1-9]|10|11|12|13) ;;
        *) printf "${RED}Servidor invalido.${RESET}\n"; sleep 2; return ;;
    esac

    url=`server_url "$srv"`
    tag=`server_tag "$srv"`

    printf "Usuario (%s): " "$url"
    read -r user
    [ -z "$user" ] && printf "${RED}Usuario vazio.${RESET}\n" && sleep 2 && return

    # Verifica duplicata
    if [ -f "$ACCOUNTS_FILE" ] && grep -q "^${srv}|${user}|" "$ACCOUNTS_FILE" 2>/dev/null; then
        printf "${RED}Conta [%s] %s ja existe.${RESET}\n" "$tag" "$user"
        sleep 2; return
    fi

    printf "Senha: "
    stty -echo 2>/dev/null
    read -r pass
    stty echo 2>/dev/null
    printf "\n"
    [ -z "$pass" ] && printf "${RED}Senha vazia.${RESET}\n" && sleep 2 && return

    printf "Testando login em %s...\n" "$url"

    if test_login "https://$url" "$user" "$pass"; then
        encoded=`printf "login=%s&pass=%s" "$user" "$pass" | base64 -w 0`
        printf "%s|%s|%s\n" "$srv" "$user" "$encoded" >> "$ACCOUNTS_FILE"
        printf "${GREEN}[OK] Conta [%s] %s adicionada!${RESET}\n" "$tag" "$user"
    else
        printf "${RED}Login nao confirmado automaticamente.${RESET}\n"
        printf "Isso pode ocorrer por bloqueio de IP no teste.\n"
        printf "Salvar a conta mesmo assim? (y/n): "
        read -r force
        case "$force" in
            y|Y)
                encoded=`printf "login=%s&pass=%s" "$user" "$pass" | base64 -w 0`
                printf "%s|%s|%s\n" "$srv" "$user" "$encoded" >> "$ACCOUNTS_FILE"
                printf "${GOLD}Conta salva sem validacao de login.${RESET}\n"
                ;;
            *) printf "Conta nao salva.\n" ;;
        esac
    fi

    unset pass encoded
    sleep 2
}

remove_account() {
    clear
    printf "${CYAN}=== Remover conta ===${RESET}\n\n"
    [ ! -f "$ACCOUNTS_FILE" ] || [ ! -s "$ACCOUNTS_FILE" ] && \
        printf "${RED}Nenhuma conta.${RESET}\n" && sleep 2 && return

    n=1
    while IFS='|' read -r srv user _enc; do
        case "$srv" in ''|\#*) continue ;; esac
        tag=`server_tag "$srv"`
        printf "${GOLD}%d)${RESET} [%s] %s\n" "$n" "$tag" "$user"
        n=$((n + 1))
    done < "$ACCOUNTS_FILE"

    printf "\nNumero (0 = cancelar): "
    read -r choice
    [ "$choice" = "0" ] || [ -z "$choice" ] && return

    total=`grep -c '' "$ACCOUNTS_FILE"`
    if ! echo "$choice" | grep -qE '^[0-9]+$' || \
       [ "$choice" -lt 1 ] || [ "$choice" -gt "$total" ]; then
        printf "${RED}Invalido.${RESET}\n"; sleep 2; return
    fi

    line=`sed -n "${choice}p" "$ACCOUNTS_FILE"`
    srv=`echo "$line" | cut -d'|' -f1`
    user=`echo "$line" | cut -d'|' -f2`
    tag=`server_tag "$srv"`

    printf "Remover [%s] %s? (y/n): " "$tag" "$user"
    read -r confirm
    case "$confirm" in
        y|Y)
            sed -i "${choice}d" "$ACCOUNTS_FILE"
            printf "${GREEN}Removida.${RESET}\n"
            acc_dir="$HOME/.twm/${tag}_${user}"
            if [ -d "$acc_dir" ]; then
                printf "Remover dados em %s? (y/n): " "$acc_dir"
                read -r rd
                case "$rd" in y|Y) rm -rf "$acc_dir" && printf "Dados removidos.\n" ;; esac
            fi
            ;;
        *) printf "Cancelado.\n" ;;
    esac
    sleep 2
}

test_account() {
    clear
    printf "${CYAN}=== Testar login ===${RESET}\n\n"
    [ ! -f "$ACCOUNTS_FILE" ] || [ ! -s "$ACCOUNTS_FILE" ] && \
        printf "${RED}Nenhuma conta.${RESET}\n" && sleep 2 && return

    n=1
    while IFS='|' read -r srv user _enc; do
        case "$srv" in ''|\#*) continue ;; esac
        tag=`server_tag "$srv"`
        printf "${GOLD}%d)${RESET} [%s] %s\n" "$n" "$tag" "$user"
        n=$((n + 1))
    done < "$ACCOUNTS_FILE"

    printf "\nNumero: "
    read -r choice
    total=`grep -c '' "$ACCOUNTS_FILE"`
    if ! echo "$choice" | grep -qE '^[0-9]+$' || \
       [ "$choice" -lt 1 ] || [ "$choice" -gt "$total" ]; then
        printf "${RED}Invalido.${RESET}\n"; sleep 2; return
    fi

    line=`sed -n "${choice}p" "$ACCOUNTS_FILE"`
    srv=`echo "$line" | cut -d'|' -f1`
    user=`echo "$line" | cut -d'|' -f2`
    encoded=`echo "$line" | cut -d'|' -f3`
    tag=`server_tag "$srv"`
    url=`server_url "$srv"`

    creds=`echo "$encoded" | base64 -d 2>/dev/null`
    luser=`echo "$creds" | sed 's/login=//;s/&pass=.*//'`
    lpass=`echo "$creds" | sed 's/.*&pass=//'`
    unset creds

    printf "Testando [%s] %s...\n" "$tag" "$user"

    if test_login "https://$url" "$luser" "$lpass"; then
        printf "${GREEN}[OK] Login confirmado.${RESET}\n"
    else
        printf "${RED}[FALHOU] Login nao confirmado.${RESET}\n"
        printf "Nota: pode ser bloqueio de IP. O bot pode funcionar mesmo assim.\n"
    fi
    unset lpass
    sleep 3
}

# Loop principal
while true; do
    show_menu
    read -r opt
    case "$opt" in
        1) list_accounts ;;
        2) add_account ;;
        3) remove_account ;;
        4) test_account ;;
        0) printf "\nSaindo...\n"; exit 0 ;;
    esac
done
