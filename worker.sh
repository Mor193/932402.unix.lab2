#!/bin/sh -e

SHARED_DIR="/shared"
LOCK_FILE="$SHARED_DIR/.lock"
CONTAINER_ID=$(cat /proc/sys/kernel/random/uuid)
SEQ_NUM=0
CURRENT_FILE=""

exit_handler() {
    rc=$?
    trap - EXIT
    if [ -n "$CURRENT_FILE" ] && [ -e "$SHARED_DIR/$CURRENT_FILE" ]; then
        rm -f -- "$SHARED_DIR/$CURRENT_FILE"
    fi
    exit $rc
}

trap exit_handler EXIT HUP INT QUIT PIPE TERM

mkdir -p "$SHARED_DIR"

while true; do
    SEQ_NUM=$((SEQ_NUM + 1))

    CURRENT_FILE=$(
        (
            flock 9 || exit 1
            i=1
            while true; do
                fname=$(printf "%03d" "$i")
                if [ ! -e "$SHARED_DIR/$fname" ]; then
                    echo "$CONTAINER_ID $SEQ_NUM" > "$SHARED_DIR/$fname"
                    echo "$fname"
                    break
                fi
                i=$((i + 1))
            done
        ) 9>"$LOCK_FILE"
    )

    sleep 1

    rm -f -- "$SHARED_DIR/$CURRENT_FILE"
    CURRENT_FILE=""

    sleep 1
done