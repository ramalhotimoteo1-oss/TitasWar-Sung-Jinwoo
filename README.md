# 🚀 TitasWarPro (TWM) - Termux + Toybox

Versão simplificada para rodar no Termux antigo usando Toybox.

---

## 📱 Instalação (Termux)

# Atualiza o Termux
pkg update
pkg upgrade -y

---

# Instala dependências básicas
pkg install git curl wget jq -y

---

# Cria pasta do Toybox
mkdir -p ~/.multcf

# Baixa o Toybox compatível
curl -L -o ~/.multcf/toybox https://landley.net/toybox/bin/toybox-armv7l

# Dá permissão de execução
chmod +x ~/.multcf/toybox

---

# Baixa o bot
git clone https://github.com/hugoviegas/TitasWarPro-Mult-contas.git

# Entra na pasta
cd TitasWarPro-Mult-contas

---

# Dá permissão aos scripts

chmod +x play.sh
chmod +x setup.sh

---

# Configurar contas
./setup.sh

---

# Executa o bot
./play.sh

---

## 🛑 Parar

CTRL + C

---

## 🧹 Remover

rm -rf ~/TitasWarPro-Mult-contas
rm -rf ~/.multcf
