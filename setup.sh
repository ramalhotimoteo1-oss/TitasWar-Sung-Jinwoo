#!/bin/sh
# setup.sh - Gerenciamento de contas do TWM Multi-contas

_dir=`dirname "$0"`
TWMDIR=`cd "$_dir" && pwd`
unset _dir

ACCOUNTS_FILE="$TWMDIR/accounts.conf"

# Cores
GREEN='\033[32m'
GOLD='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[01;36m'
RESET='\033[00m'

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

server_name() {
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

show_menu() {
    clear
    printf "${CYAN}╔══════════════════════════════════════╗${RESET}\n"
    printf "${CYAN}║     TWM Multi-contas — Setup         ║${RESET}\n"
    printf "${CYAN}╚══════════════════════════════════════╝${RESET}\n\n"
    printf "${GOLD}1)${RESET} Listar contas cadastradas\n"
    printf "${GOLD}2)${RESET} Adicionar conta\n"
    printf "${GOLD}3)${RESET} Remover conta\n"
    printf "${GOLD}4)${RESET} Testar login de uma conta\n"
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
        while IFS='|' read -r srv user _pass; do
            url=`server_url "$srv"`
            tag=`server_name "$srv"`
            printf "${GOLD}%d)${RESET} [%s] %s — %s\n" "$n" "$tag" "$user" "$url"
            n=$((n + 1))
        done < "$ACCOUNTS_FILE"
    fi
    printf "\nENTER para voltar..."
    read -r _dummy
}

show_servers() {
    printf "\n${CYAN}Servidores disponíveis:${RESET}\n"
    printf " 1)  BR — furiadetitas.net\n"
    printf " 2)  DE — titanen.mobi\n"
    printf " 3)  ES — guerradetitanes.net\n"
    printf " 4)  FR — tiwar.fr\n"
    printf " 5)  IN — in.tiwar.net\n"
    printf " 6)  ID — tiwar-id.net\n"
    printf " 7)  IT — guerraditiani.net\n"
    printf " 8)  PL — tiwar.pl\n"
    printf " 9)  RO — tiwar.ro\n"
    printf "10)  RU — tiwar.ru\n"
    printf "11)  SR — rs.tiwar.net\n"
    printf "12)  ZH — cn.tiwar.net\n"
    printf "13)  EN — tiwar.net\n"
}

add_account() {
    clear
    printf "${CYAN}=== Adicionar conta ===${RESET}\n"
    show_servers
    printf "\nNumero do servidor: "
    read -r srv

    case "$srv" in
        [1-9]|10|11|12|13) ;;
        *)
            printf "${RED}Servidor invalido.${RESET}\n"
            sleep 2
            return
            ;;
    esac

    url=`server_url "$srv"`
    tag=`server_name "$srv"`

    printf "Usuario (%s): " "$url"
    read -r user

    if [ -z "$user" ]; then
        printf "${RED}Usuario nao pode ser vazio.${RESET}\n"
        sleep 2
        return
    fi

    # Verifica se conta ja existe
    if [ -f "$ACCOUNTS_FILE" ] && grep -q "^${srv}|${user}|" "$ACCOUNTS_FILE" 2>/dev/null; then
        printf "${RED}Conta [%s] %s ja esta cadastrada.${RESET}\n" "$tag" "$user"
        sleep 2
        return
    fi

    printf "Senha: "
    stty -echo 2>/dev/null
    read -r pass
    stty echo 2>/dev/null
    printf "\n"

    if [ -z "$pass" ]; then
        printf "${RED}Senha nao pode ser vazia.${RESET}\n"
        sleep 2
        return
    fi

    # Testa login antes de salvar
    printf "Testando login em %s...\n" "$url"
    result=`curl -s -L -c /tmp/twm_test_cookie.txt -b /tmp/twm_test_cookie.txt \
        --data-urlencode "login=${user}" \
        --data-urlencode "pass=${pass}" \
        "https://${url}/?sign_in=1"`

    rm -f /tmp/twm_test_cookie.txt

    if echo "$result" | grep -q '?exit\|sign_out\|logout'; then
        # Salva credencial criptografada em base64
        encoded=`printf "login=%s&pass=%s" "$user" "$pass" | base64 -w 0`
        printf "%s|%s|%s\n" "$srv" "$user" "$encoded" >> "$ACCOUNTS_FILE"
        printf "\n${GREEN}Conta [%s] %s adicionada com sucesso!${RESET}\n" "$tag" "$user"
    else
        printf "\n${RED}Login falhou. Verifique usuario e senha.${RESET}\n"
        printf "Deseja salvar mesmo assim? (y/n): "
        read -r force
        case "$force" in
            y|Y)
                encoded=`printf "login=%s&pass=%s" "$user" "$pass" | base64 -w 0`
                printf "%s|%s|%s\n" "$srv" "$user" "$encoded" >> "$ACCOUNTS_FILE"
                printf "${GOLD}Conta salva sem validacao.${RESET}\n"
                ;;
            *)
                printf "Conta nao salva.\n"
                ;;
        esac
    fi

    unset pass encoded
    sleep 2
}

remove_account() {
    clear
    printf "${CYAN}=== Remover conta ===${RESET}\n\n"

    if [ ! -f "$ACCOUNTS_FILE" ] || [ ! -s "$ACCOUNTS_FILE" ]; then
        printf "${RED}Nenhuma conta cadastrada.${RESET}\n"
        sleep 2
        return
    fi

    n=1
    while IFS='|' read -r srv user _pass; do
        tag=`server_name "$srv"`
        printf "${GOLD}%d)${RESET} [%s] %s\n" "$n" "$tag" "$user"
        n=$((n + 1))
    done < "$ACCOUNTS_FILE"

    printf "\nNumero da conta para remover (0 = cancelar): "
    read -r choice

    if [ "$choice" = "0" ] || [ -z "$choice" ]; then
        return
    fi

    # Valida numero
    total=`wc -l < "$ACCOUNTS_FILE"`
    if ! echo "$choice" | grep -qE '^[0-9]+$' || [ "$choice" -lt 1 ] || [ "$choice" -gt "$total" ]; then
        printf "${RED}Opcao invalida.${RESET}\n"
        sleep 2
        return
    fi

    line=`sed -n "${choice}p" "$ACCOUNTS_FILE"`
    srv=`echo "$line" | cut -d'|' -f1`
    user=`echo "$line" | cut -d'|' -f2`
    tag=`server_name "$srv"`

    printf "Remover [%s] %s? (y/n): " "$tag" "$user"
    read -r confirm
    case "$confirm" in
        y|Y)
            sed -i "${choice}d" "$ACCOUNTS_FILE"
            printf "${GREEN}Conta removida.${RESET}\n"

            # Oferece remover diretorio de dados tambem
            acc_dir="$HOME/.twm/${tag}_${user}"
            if [ -d "$acc_dir" ]; then
                printf "Remover dados da conta em %s? (y/n): " "$acc_dir"
                read -r rmdata
                case "$rmdata" in
                    y|Y) rm -rf "$acc_dir" && printf "Dados removidos.\n" ;;
                esac
            fi
            ;;
        *)
            printf "Cancelado.\n"
            ;;
    esac
    sleep 2
}

test_account() {
    clear
    printf "${CYAN}=== Testar login ===${RESET}\n\n"

    if [ ! -f "$ACCOUNTS_FILE" ] || [ ! -s "$ACCOUNTS_FILE" ]; then
        printf "${RED}Nenhuma conta cadastrada.${RESET}\n"
        sleep 2
        return
    fi

    n=1
    while IFS='|' read -r srv user _pass; do
        tag=`server_name "$srv"`
        printf "${GOLD}%d)${RESET} [%s] %s\n" "$n" "$tag" "$user"
        n=$((n + 1))
    done < "$ACCOUNTS_FILE"

    printf "\nNumero da conta para testar: "
    read -r choice

    total=`wc -l < "$ACCOUNTS_FILE"`
    if ! echo "$choice" | grep -qE '^[0-9]+$' || [ "$choice" -lt 1 ] || [ "$choice" -gt "$total" ]; then
        printf "${RED}Opcao invalida.${RESET}\n"
        sleep 2
        return
    fi

    line=`sed -n "${choice}p" "$ACCOUNTS_FILE"`
    srv=`echo "$line" | cut -d'|' -f1`
    user=`echo "$line" | cut -d'|' -f2`
    encoded=`echo "$line" | cut -d'|' -f3`
    tag=`server_name "$srv"`
    url=`server_url "$srv"`

    creds=`echo "$encoded" | base64 -d 2>/dev/null`
    luser=`echo "$creds" | sed 's/login=//;s/&pass=.*//'`
    lpass=`echo "$creds" | sed 's/.*&pass=//'`

    printf "Testando [%s] %s em %s...\n" "$tag" "$user" "$url"

    result=`curl -s -L -c /tmp/twm_test_cookie.txt -b /tmp/twm_test_cookie.txt \
        --data-urlencode "login=${luser}" \
        --data-urlencode "pass=${lpass}" \
        "https://${url}/?sign_in=1"`

    rm -f /tmp/twm_test_cookie.txt
    unset lpass creds

    if echo "$result" | grep -q '?exit\|sign_out\|logout'; then
        printf "${GREEN}Login OK — sessao ativa.${RESET}\n"
    else
        printf "${RED}Login FALHOU.${RESET}\n"
    fi
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
        *) ;;
    esac
done
