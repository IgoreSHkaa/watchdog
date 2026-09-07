#!/bin/bash

GITHUB_TOKEN="токен"
REPO_OWNER="владелец"
REPO_NAME="репозиторий"
RUNNER_NAME="раннер"
ZABBIX_SERVER="ип"
ZABBIX_HOST="хост"
MAX_LAST_CONTACT_MINUTES=10



if ! pgrep -f "Runner.Listener" >/dev/null; then
	STATUS=0
	REASON="process_down"
else
	if [ -n "$REPO_NAME" ]; then
		API="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runners"
	else
		API="https://api.github.com/orgs/$REPO_OWNER/actions/runners"
	fi

	INFO=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$API" | \
		jq -r --arg N "$RUNNER_NAME" '.runners[]? | select(.name == $N) | [.status,.last_contact] | @tsv')

	if [ -z "$INFO" ]; then
		STATUS=0
        REASON="runner_not_found"
	else
		read -r S L <<< "$INFO"
		if [ "$S" != "online" ]; then
			STATUS=0
			REASON="runner_offline"
	elif [ -z "$L" ]; then
		STATUS=0
		REASON="no_last_contact"
	else
		NOW=$(date +%s)
		LAST=$(date -d "$L" +%s 2>/dev/null)
		if [ -z "$LAST" ]; then
        	STATUS=0
			REASON="invalid_last_contact"
	else
		DIFF=$(( (NOW - LAST) / 60 ))
		if [ "$DIFF" -gt "$MAX_LAST_CONTACT_MINUTES" ]; then
			STATUS=0
			REASON="zombie_${DIFF}min"
	else
            STATUS=1
            REASON="OK"
			fi
		fi
	fi
fi

zabbix_sender -z "$ZABBIX_SERVER" \
    -s "$ZABBIX_HOST" \
    -k runner.status \
    -o "$STATUS"

zabbix_sender -z "$ZABBIX_SERVER" \
    -s "$ZABBIX_HOST" \
    -k runner.reason \
    -o "$REASON"

