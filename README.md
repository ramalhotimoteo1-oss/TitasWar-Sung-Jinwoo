🧰 1. Instalar o Termux (jeito correto)
Não use o da Play Store (está desatualizado).
Baixe o mais recente pelo F-Droid:
https://f-droid.org/packages/com.termux/⁠�
Depois abra o Termux.
🔧 2. Preparar o Termux (OBRIGATÓRIO após update novo)
Cole tudo de uma vez:
Bash
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
Agora permita acesso aos arquivos:
Bash
termux-setup-storage
Aceite a permissão.
📥 3. Baixar o TitansWarPro-Mult-contas
Agora você pode baixar em qualquer pasta.
Exemplo 1 (na home):
Bash
cd ~
git clone https://github.com/ramalhotimoteo1-oss/TitasWarPro-Mult-contas.git
Exemplo 2 (em pasta personalizada):
Bash
mkdir twm
cd twm
git clone https://github.com/ramalhotimoteo1-oss/TitasWarPro-Mult-contas.git
Exemplo 3 (direto com nome curto):
Bash
git clone https://github.com/ramalhotimoteo1-oss/TitasWarPro-Mult-contas.git twm
cd twm
Agora entre na pasta:
Bash
cd TitasWarPro-Mult-contas
ou
Bash
cd twm
(depende de como você clonou)
🔐 4. Corrigir permissões (IMPORTANTE)
Depois do clone:
Bash
chmod +x *.sh
Agora converter arquivos (evita erro login infinito):
Bash
dos2unix *.sh
▶️ 5. Rodar o bot
Execute:
Bash
./play.sh
Vai aparecer:

Please wait...
Checking if user matches...
Username:
Digite:

usuario
senha
E pronto.
