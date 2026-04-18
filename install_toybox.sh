#!/bin/sh
# install_toybox.sh - Instala e verifica toybox no Termux

GREEN='\033[32m'
GOLD='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[01;36m'
RESET='\033[00m'

printf "${CYAN}=== TWM Toybox Installer ===${RESET}\n\n"

# Metodo 1: pkg install toybox
printf "Tentando instalar via pkg...\n"
if pkg install toybox -y 2>/dev/null; then
    TOYBOX_BIN=$(which toybox 2>/dev/null)
    if [ -n "$TOYBOX_BIN" ]; then
        printf "${GREEN}toybox instalado: %s${RESET}\n" "$TOYBOX_BIN"
    fi
fi

# Metodo 2: download binario aarch64
if [ ! -x "/data/data/com.termux/files/usr/bin/toybox" ] && \
   [ ! -x "/data/data/com.termux/files/home/toybox-aarch64" ]; then
    printf "${GOLD}Baixando binario toybox-aarch64...${RESET}\n"
    curl -L "https://landley.net/toybox/bin/toybox-aarch64" \
        -o "$HOME/toybox-aarch64" 2>/dev/null
    chmod +x "$HOME/toybox-aarch64" 2>/dev/null
fi

printf "\n${CYAN}=== Verificacao ===${RESET}\n"

# Verifica os possiveis caminhos
for path in \
    "/data/data/com.termux/files/home/toybox-aarch64" \
    "/data/data/com.termux/files/usr/bin/toybox" \
    "/usr/bin/toybox"; do
    if [ -x "$path" ]; then
        ver=$("$path" --version 2>/dev/null | head -n1)
        printf "${GREEN}[OK]${RESET} %s — %s\n" "$path" "$ver"
    else
        printf "${RED}[--]${RESET} %s\n" "$path"
    fi
done

printf "\n${CYAN}=== Teste de execucao ===${RESET}\n"

TOYBOX_SH=""
for _tb in \
    "/data/data/com.termux/files/home/toybox-aarch64" \
    "/data/data/com.termux/files/usr/bin/toybox" \
    "/usr/bin/toybox"; do
    if [ -x "$_tb" ]; then
        TOYBOX_SH="$_tb sh"
        break
    fi
done

if [ -n "$TOYBOX_SH" ]; then
    result=$($TOYBOX_SH -c 'echo "toybox sh ok"' 2>/dev/null)
    if [ "$result" = "toybox sh ok" ]; then
        printf "${GREEN}Toybox sh funcional: %s${RESET}\n" "$TOYBOX_SH"
    else
        printf "${RED}Toybox sh falhou — usando sh padrao${RESET}\n"
    fi
else
    printf "${RED}Toybox nao encontrado — usando sh padrao${RESET}\n"
fi

printf "\n${CYAN}=== Instrucoes ===${RESET}\n"
printf "1. Instalar:  ${GOLD}pkg install toybox${RESET}\n"
printf "   OU baixar: ${GOLD}curl -L https://landley.net/toybox/bin/toybox-aarch64 -o ~/toybox-aarch64 && chmod +x ~/toybox-aarch64${RESET}\n"
printf "\n2. Executar o bot:\n"
printf "   ${GOLD}./play.sh${RESET}          (detecta toybox automaticamente)\n"
printf "   ${GOLD}./play.sh -cv${RESET}       (modo caverna)\n"
printf "   ${GOLD}./play.sh -cl${RESET}       (modo coliseu)\n"
printf "\n3. Verificar shell em uso:\n"
printf "   O monitor mostra o shell ativo na linha de titulo\n"
printf "\n4. Parar tudo:\n"
printf "   ${GOLD}./stop.sh${RESET}\n"
