#!/bin/bash

. /etc/cloudflare.sh
. /opt/container-scripts/_common.sh

removeRecord() {
	RECORD_ID="$1"; shift
	curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/dns_records/${RECORD_ID}" \
		-H "X-Auth-Email: ${CLOUDFLARE_USER}" \
		-H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
		-H "Content-Type: application/json"
}

getRecords() {
	HOST_NAME="$1"; shift
	curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/dns_records?name=${HOST_NAME}&page=1&per_page=50&&order=type&direction=desc&match=all" \
		-H "X-Auth-Email: ${CLOUDFLARE_USER}" \
		-H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
		-H "Content-Type: application/json" | jq -r '.result | .[] | select(.name=="'"$HOST_NAME"'" and .type == "TXT") | .id'
}

addRecord() {
	HOST_NAME="$1"; shift
	VALUE="$1"; shift
	curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/dns_records" \
		-H "X-Auth-Email: ${CLOUDFLARE_USER}" \
		-H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
		-H "Content-Type: application/json" \
		--data '{"type":"TXT","name":"'"${HOST_NAME}"'","content":"'"${VALUE}"'","ttl":120,"proxied":false}'
}


REAL_VERIFICATION_DOMAIN="_acme-challenge.${WEB_FQDNALIASES_MAP[$CERTBOT_DOMAIN]}.${BASE_DOMAIN}"
CURRENT_RECORDS=( $(getRecords "$REAL_VERIFICATION_DOMAIN") )

for CURRENT_RECORD in ${CURRENT_RECORDS[@]}; do
	removeRecord "$CURRENT_RECORD"
	echo
done

addRecord "$REAL_VERIFICATION_DOMAIN" "$CERTBOT_VALIDATION"
echo

echo waiting 10 seconds for the TXT-record to propagate
sleep 10
