#!/bin/bash

. /opt/container-scripts/certbot-telemedhelp-authenticator-hook/_common.sh

CURRENT_RECORDS=( $(getRecords "$REAL_VERIFICATION_DOMAIN") )

for CURRENT_RECORD in ${CURRENT_RECORDS[@]}; do
	CLOUDFLARE_DOMAIN="$(getDomain "$REAL_VERIFICATION_DOMAIN")"
	removeRecord "${CLOUDFLARE_ZONE[$CLOUDFLARE_DOMAIN]}" "$CURRENT_RECORD"
	RC="$?"
	if [ "$RC" != '0' ]; then
		exit $RC
	fi
done
