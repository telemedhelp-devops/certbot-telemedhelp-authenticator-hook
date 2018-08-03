#!/bin/bash

. /opt/container-scripts/certbot-telemedhelp-authenticator-hook/_common.sh

echo "${REAL_VERIFICATION_DOMAIN}:"

/opt/container-scripts/certbot-telemedhelp-authenticator-hook/cleanup-hook.sh

addRecord "$REAL_VERIFICATION_DOMAIN" "$CERTBOT_VALIDATION"
RC="$?"
if [ "$RC" != '0' ]; then
	exit $RC
fi

echo "waiting 10 seconds for the TXT-record of $REAL_VERIFICATION_DOMAIN to propagate"
sleep 10
