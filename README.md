# 🚀 TitasWarPro (TWM) - Multi Contas

Automação completa para o jogo TitansWar.

---

## 📱 Termux (Android - versão antiga ⚠️)

# Atualiza a lista de pacotes
pkg update

# Atualiza todos os pacotes instalados
pkg upgrade -y

---

# Instala o Git
pkg install git

# Instala o Curl (download de arquivos)
pkg install curl

# Instala o Wget (download alternativo)
pkg install wget

# Instala navegador em terminal
pkg install w3m

# Instala o jq (OBRIGATÓRIO para o bot)
pkg install jq

# Instala utilitários de processos
pkg install procps

# Instala comandos básicos do sistema
pkg install coreutils

# Instala utilitários de terminal
pkg install ncurses-utils -y

---

# Baixa o instalador do bot
curl -L -O https://raw.githubusercontent.com/hugoviegas/TitansWarPro/master/update.sh

---

# Dá permissão de execução
chmod +x update.sh

---

# Executa a instalação do bot
./update.sh

---

# Inicia o bot
./twm/play.sh

---

## ⚡ Modos

# Executa modo caverna
./twm/play.sh -cv

# Executa modo coliseu
./twm/play.sh -cl

---

## 🐧 Linux / Ubuntu / VPS

# Atualiza lista de pacotes
sudo apt update

# Atualiza o sistema
sudo apt upgrade -y

---

# Instala Git
sudo apt install git

# Instala Curl
sudo apt install curl

# Instala Wget
sudo apt install wget

# Instala navegador em terminal
sudo apt install w3m

# Instala utilitários de processos
sudo apt install procps

# Instala jq (OBRIGATÓRIO)
sudo apt install jq -y

---

# Baixa instalador
curl -L -O https://raw.githubusercontent.com/hugoviegas/TitansWarPro/master/update.sh

---

# Permissão de execução
chmod +x update.sh

---

# Instala bot
bash update.sh

---

# Executa bot
bash twm/play.sh

---

## 🧠 Multi-contas

# Edita arquivo de contas
nano accounts.txt

# Formato das contas
server|login|senha

---

## 🛑 Parar bot

CTRL + C

---

## 🧹 Desinstalar

# Remove o bot completamente
rm -rf $HOME/twm

---

## ⚠️ Problemas

# Instalar jq caso dê erro
pkg install jq -y

# Corrigir permissões
chmod +x update.sh
chmod +x twm/play.sh

# Corrigir repositório do Termux
termux-change-repo
