# 📱 TitansWarPro-Mult-contas — Tutorial Completo (Termux Atualizado)

Este tutorial ensina **do zero** como instalar e executar o **TitansWarPro-Mult-contas** no Termux.

✅ Funciona após o update novo do Termux  
✅ Funciona em qualquer diretório  
✅ Não depende mais de caminho fixo  
✅ Suporte a multi-contas  
✅ Instalação limpa e rápida  

---

# 🧰 1. Preparar o Termux (OBRIGATÓRIO)

Atualize tudo:

```bash
pkg update -y && pkg upgrade -y

pkg install git -y
pkg install curl -y
pkg install wget -y
pkg install proot -y
pkg install proot-distro -y
pkg install nano -y
pkg install dos2unix -y
pkg install grep -y
pkg install sed -y
pkg install coreutils -y
pkg install util-linux -y
pkg install openssl -y

termux-setup-storage

cd ~
git clone https://github.com/ramalhotimoteo1-oss/TitasWarPro-Mult-contas.git
cd TitasWarPro-Mult-contas

mkdir twm
cd twm
git clone https://github.com/ramalhotimoteo1-oss/TitasWarPro-Mult-contas.git .

chmod +x *.sh

./play.sh
