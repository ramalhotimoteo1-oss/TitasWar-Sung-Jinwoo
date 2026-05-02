# Wartank Bot v1.3.0

Bot automático para wartank-pt.net — funciona no Android via Termux.

---

## PARTE 1 — Instalar o Termux

**O que é o Termux?**
Terminal Linux para Android. O bot corre dentro dele.

**Passo 1** — Instala o Termux pela F-Droid (não usar a Play Store):

```
https://f-droid.org/packages/com.termux/
```

---

**Passo 2** — Abre o Termux e actualiza:

```bash
pkg update
```

```bash
pkg upgrade -y
```

---

**Passo 3** — Instala as dependências:

```bash
pkg install git
```

```bash
pkg install curl
```

```bash
pkg install bash
```

---

**Passo 4** — Verifica a instalação:

```bash
curl --version && bash --version && git --version
```

> Se aparecerem versões sem erros, está pronto.

---

## PARTE 2 — Instalar o Bot

**Passo 1** — Vai para a pasta home:

```bash
cd ~
```

---

**Passo 2** — Clona o repositório directamente como `Wartank-Macro`:

```bash
git clone https://github.com/ramalhotimoteo1-oss/TitasWar-Sung-Jinwoo.git
```

> Substitui o URL pelo repositório real do bot.
> O nome `Wartank-Macro` é obrigatório — não cria pasta dentro de pasta.

---

**Passo 3** — Entra na pasta:

```bash
cd ~/Wartank-Macro
```

---

**Passo 4** — Dá permissão de execução:

```bash
chmod +x *.sh
```

---

**Passo 5** — Confirma que os ficheiros estão lá:

```bash
ls
```

> Deves ver: `play.sh`, `wartank.sh`, `setup.sh`, `core.sh`, etc.

---

## PARTE 3 — Configurar a Conta

**Passo 1** — Abre o menu de contas:

```bash
./setup.sh
```

---

**Passo 2** — Escolhe `2) Adicionar`

**Passo 3** — Escreve o teu username

**Passo 4** — Escreve a tua password

> A password não aparece enquanto escreves — é normal e seguro.

---

## PARTE 4 — Iniciar o Bot

**Para iniciar:**

```bash
./play.sh
```

---

**Para parar — escreve no terminal:**

```
stop
```

---

**Para parar à força:**

```bash
./stop.sh
```

---

## PARTE 5 — Mudar de Conta

**Apaga as credenciais da conta anterior:**

```bash
rm -f ~/Wartank-Macro/.tmp/cript_file
```

```bash
rm -f ~/Wartank-Macro/.tmp/cookies.txt
```

**Inicia o bot — vai pedir nova conta:**

```bash
./play.sh
```

---

## PARTE 6 — Comandos Durante a Execução

Enquanto o bot está a correr, escreve no terminal:

**Abrir configurações:**

```
config
```

**Ver estado actual:**

```
status
```

**Parar o bot:**

```
stop
```

---

## PARTE 7 — Configurações

O ficheiro `config.cfg` é criado automaticamente na primeira execução.

**Para editar:**

```bash
nano config.cfg
```

**Opções disponíveis:**

```
FUNC_battle=y          → Batalha normal
FUNC_missions=y        → Recolha de missões
FUNC_pvp=y             → PvP
FUNC_pvp_hour=21       → Hora do PvP (0-23)
FUNC_pve=y             → Batalhas históricas
FUNC_cw=y              → Guerra de clã
FUNC_dm=y              → Disputa (Deathmatch)
FUNC_convoy=y          → Escolta
FUNC_buildings=y       → Recolha da Base
FUNC_assault=y         → Missão especial (sempre Abrigo)
FUNC_company=y         → Missões da Divisão

BATTLE_LA=3            → Segundos entre disparos
BATTLE_SHOTS=9         → Disparos por sessão (9 = 3 inimigos)
FUEL_MIN=0             → Combustível mínimo
ASSAULT_MIN_MEMBERS=1  → Membros para iniciar missão especial
```

**Guardar após editar:**

```
Ctrl+O  →  Enter  →  Ctrl+X
```

---

## PARTE 8 — Ver Logs

**Log em tempo real:**

```bash
tail -f ~/Wartank-Macro/.tmp/bot.log
```

**Últimas 50 linhas:**

```bash
tail -50 ~/Wartank-Macro/.tmp/bot.log
```

**Pesquisar erros:**

```bash
grep "ERRO" ~/Wartank-Macro/.tmp/bot.log
```

---

## PARTE 9 — Manter o Bot Activo

**Para o bot não ser suspenso com o ecrã desligado:**

```bash
termux-wake-lock
```

> Corre este comando antes de `./play.sh`.

---

## PARTE 10 — Actualizar o Bot

**Para actualizar com versão mais recente:**

```bash
cd ~/Wartank-Macro
```

```bash
git pull
```

```bash
chmod +x *.sh
```

---

## PARTE 11 — Resolver Problemas

---

**Bot fica na mesma conta mesmo apagando credenciais**

Apaga os dois ficheiros:

```bash
rm -f ~/Wartank-Macro/.tmp/cript_file
```

```bash
rm -f ~/Wartank-Macro/.tmp/cookies.txt
```

---

**"Config não encontrado. A criar..." em loop**

Garante que entras sempre na pasta antes de iniciar:

```bash
cd ~/Wartank-Macro
```

```bash
./play.sh
```

---

**Bot não combate**

Verifica o log:

```bash
tail -50 ~/Wartank-Macro/.tmp/bot.log
```

Causas mais comuns:
- Combustível abaixo de 90 (mínimo para 1 inimigo)
- `FUNC_battle=n` no `config.cfg`

---

**Sessão expira com frequência**

Normal em ligações móveis — o bot reconecta automaticamente.
Se falhar 3 vezes seguidas, para e reinicia com:

```bash
./play.sh
```

---

**Pasta Wartank-Macro dentro de Wartank-Bot**

Apaga e clona de novo correctamente:

```bash
cd ~
```

```bash
rm -rf Wartank-Bot
```

```bash
git clone https://github.com/SEU_USER/SEU_REPO.git Wartank-Macro
```

---

## Resumo Rápido

| O que fazer | Comando |
|---|---|
| Actualizar Termux | `pkg update && pkg upgrade -y` |
| Instalar git | `pkg install git` |
| Instalar curl/bash | `pkg install curl bash` |
| Clonar o bot | `git clone URL Wartank-Macro` |
| Entrar na pasta | `cd ~/Wartank-Macro` |
| Permissões | `chmod +x *.sh` |
| Adicionar conta | `./setup.sh` |
| Iniciar | `./play.sh` |
| Parar | escreve `stop` |
| Ver log | `tail -f .tmp/bot.log` |
| Wake lock | `termux-wake-lock` |
| Actualizar bot | `git pull` |
