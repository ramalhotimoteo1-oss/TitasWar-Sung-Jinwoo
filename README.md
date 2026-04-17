# TWM — Titans War Macro v3.9.28

Bot multi-contas para [titanswar.net](https://titanswar.net) e todos os servidores. Automatiza as tarefas diárias do jogo rodando em segundo plano no Termux.

**Requisito mínimo:** level 16+ e 50 pontos de treinamento para algumas batalhas.

---

## O que o bot faz

- **Arena** — joga automaticamente até acabar a mana
- **Carreira** — batalha e coleta recompensas sempre que disponível
- **Coliseu** — batalha de 00:00 às 04:00 todo dia; modo exclusivo disponível
- **Caverna** — todas as funções, incluindo loop contínuo
- **Campanha** — 100% funcional
- **Masmorra do Clã** — entra sempre que disponível
- **Rei dos Imortais** — participa com modo sniper de finalização
- **Eventos diários** — todos funcionando, incluindo eventos temporários
- **Troca de ouro/prata** — sempre que disponível
- **Cabana do Sábio** — coleta missões, coleções e relíquias

**Segurança:** sua senha é criptografada localmente em base64 e nunca é enviada para nenhum servidor externo.

---

## Sobre o Toybox

O bot usa o [Toybox](https://landley.net/toybox/) como utilitário de sistema para garantir comandos consistentes em dispositivos Android antigos. Os scripts são executados pelo `sh` nativo do Termux — o Toybox serve como suporte de coreutils, não como interpretador.

---

## Instalação no Termux

> Instale o Termux pela [F-Droid](https://f-droid.org/packages/com.termux/) — a versão da Play Store está desatualizada.

---

### 1. Atualiza o Termux

Mantém os pacotes do sistema em dia. Responda `Y` para qualquer confirmação e pressione `ENTER` para opções múltiplas.

```bash
pkg update && pkg upgrade -y
```

---

### 2. Instala as dependências

Instala `curl`, `git`, `jq` e demais utilitários necessários para o bot funcionar.

```bash
pkg install git curl wget jq -y
```

---

### 3. Cria a pasta do Toybox

Cria o diretório onde o binário do Toybox ficará armazenado.

```bash
mkdir -p ~/.multcf
```

---

### 4. Baixa o Toybox

Detecta sua arquitetura e baixa o binário correto automaticamente.

```bash
ARCH=$(uname -m) && \
case "$ARCH" in
  aarch64) TB="toybox-aarch64" ;;
  armv7l)  TB="toybox-armv7l"  ;;
  armv5*)  TB="toybox-armv5l"  ;;
  x86_64)  TB="toybox-x86_64"  ;;
  i686)    TB="toybox-i686"    ;;
  *)       TB="toybox-aarch64" ;;
esac && \
curl -L -o ~/.multcf/toybox "https://landley.net/toybox/bin/$TB"
```

---

### 5. Dá permissão de execução ao Toybox

```bash
chmod +x ~/.multcf/toybox
```

---

### 6. Baixa o bot

Clona o repositório na pasta atual do Termux.

```bash
git clone https://github.com/ramalhotimoteo1-oss/TitasWar-Sung-Jinwoo.git
```

---

### 7. Entra na pasta do bot

```bash
cd TitasWar-Sung-Jinwoo
```

---

### 8. Dá permissão de execução aos scripts principais

```bash
chmod +x play.sh setup.sh stop.sh worker.sh twm.sh
```

---

### 9. Cadastra as contas

Abre o menu interativo para adicionar, listar ou remover contas. Cada conta é salva com as credenciais criptografadas em `accounts.conf`.

```bash
./setup.sh
```

---

### 10. Inicia o bot

Inicia todos os workers em paralelo e abre o monitor de status.

```bash
./play.sh
```

---

## Modos de execução

Modo padrão — roda todas as tarefas normalmente:

```bash
./play.sh
```


---

## Monitorar uma conta específica

Exibe o log em tempo real de uma conta. Substitua `BR_NomeConta` pelo tag e nome corretos.

```bash
tail -f ~/.twm/BR_NomeConta/twm.log
```

---

## Parar o bot

Para todos os workers de todas as contas.

```bash
./stop.sh
```

---

## Desinstalar

Remove todos os arquivos do bot e os dados gerados.

```bash
cd ~ && rm -rf TitasWarPro-Mult-contas ~/.twm ~/.multcf
```

---

## ☕ Donates / Doações
