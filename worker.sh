#!/bin/sh
# worker.sh - Loop de uma conta individual
# Chamado pelo play.sh via nohup — completamente desanexado do terminal pai
# Argumentos: SRV USER ENCODED_CREDS TAG URL ACC_DIR STATUS_FILE RUN

TWM_SRV="$1"
TWM_USER="$2"
TWM_ENCODED="$3"
TWM_TAG="$4"
TWM_URL="$5"
TWM_ACC_DIR="$6"
TWM_STATUS_FILE="$7"
RUN="${8:--boot}"

export TWM_SRV TWM_USER TWM_TAG TWM_URL TWM_ACC_DIR TWM_STATUS_FILE

_dir=`dirname "$0"`
TWMDIR=`cd "$_dir" && pwd`
unset _dir
export TWMDIR

PID_FILE="${TWM_STATUS_FILE%.status}.pid"

# Salva o PID DESTE processo (worker.sh em si)
echo "$$" > "$PID_FILE"
echo "starting" > "$TWM_STATUS_FILE"

printf "[%s] %s — worker PID=%s iniciado\n" "$TWM_TAG" "$TWM_USER" "$$"

# Prepara credencial
mkdir -p "$TWM_ACC_DIR"
echo "$TWM_ENCODED" > "$TWM_ACC_DIR/cript_file"
chmod 600 "$TWM_ACC_DIR/cript_file"
unset TWM_ENCODED

# Loop infinito — reinicia twm.sh se encerrar
while true; do
    echo "running" > "$TWM_STATUS_FILE"
    sh "$TWMDIR/twm.sh" "$RUN" < /dev/null
    echo "restarting" > "$TWM_STATUS_FILE"
    printf "[%s] %s — reiniciando em 15s\n" "$TWM_TAG" "$TWM_USER"
    sleep 15
done
