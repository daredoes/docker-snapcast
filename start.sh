#!/bin/sh
FILE=/config/snapserver.conf
if test -f "$FILE"; then
    echo "$FILE exists, copying to config folder."
    cat $FILE > /etc/snapserver.conf
fi

# nqptp &
# rc-service dbus start

# /usr/bin/dbus-daemon --system
# avahi2dns &
nqptp &
# (cd /snapweb && nvm use && yarn && yarn build)
# rc-service shairport-sync zap
echo "NQPTP Launched"
snapserver