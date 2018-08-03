
. /opt/container-scripts/_common.sh

declare -A CLOUDFLARE_ZONE
. /etc/cloudflare.sh

getDomain() {
	HOST_NAME="$1"; shift

	echo "$HOST_NAME" | grep -oE '[^.]*\.[^.]*$'
}

removeRecord() {
	ZONE_ID="$1"; shift
	RECORD_ID="$1"; shift

	curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
		-H "X-Auth-Email: ${CLOUDFLARE_USER}" \
		-H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
		-H "Content-Type: application/json"
	RC="$?"
	echo
	return $RC
}

addRecord() {
	HOST_NAME="$1"; shift
	VALUE="$1"; shift

	CLOUDFLARE_DOMAIN="`getDomain "$HOST_NAME"`"
	curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE[$CLOUDFLARE_DOMAIN]}/dns_records" \
		-H "X-Auth-Email: ${CLOUDFLARE_USER}" \
		-H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
		-H "Content-Type: application/json" \
		--data '{"type":"TXT","name":"'"${HOST_NAME}"'","content":"'"${VALUE}"'","ttl":120,"proxied":false}'
	RC="$?"
	echo
	return $RC
}

getRecords() {
	HOST_NAME="$1"; shift

	CLOUDFLARE_DOMAIN="`getDomain "$HOST_NAME"`"
	curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE[$CLOUDFLARE_DOMAIN]}/dns_records?name=${HOST_NAME}&page=1&per_page=50&order=type&direction=desc&match=all" \
		-H "X-Auth-Email: ${CLOUDFLARE_USER}" \
		-H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
		-H "Content-Type: application/json" | jq -r '.result | .[] | select(.name=="'"$HOST_NAME"'" and .type == "TXT") | .id'
	return $?
}


if [ "${ALIAS_AUTHED_CERTS_MAP[$CERTBOT_DOMAIN]}" != '' ]; then
	REAL_HOST="${ALIAS_AUTHED_CERTS_MAP[$CERTBOT_DOMAIN]}.${BASE_DOMAIN}"
else
	REAL_HOST="$CERTBOT_DOMAIN"
fi
REAL_VERIFICATION_DOMAIN="_acme-challenge.$REAL_HOST"
