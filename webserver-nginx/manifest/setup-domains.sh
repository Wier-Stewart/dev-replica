#!/bin/bash
set -e

STATUS_QUEUE="/var/www/html/status"
SETUP_QUEUE='/tmp/domain-setup-queue'

    mkdir -p "$STATUS_QUEUE"
    chmod -R 777 "$STATUS_QUEUE"
    mkdir -p "$SETUP_QUEUE"
    chmod -R 777 "$SETUP_QUEUE"

    echo "";

    cd "$SETUP_QUEUE";
# silence errors = " 2>/dev/null "
    domainlist=$(find * -name '*.txt' -type f -maxdepth 1 2>/dev/null | cut -d'.' -f1-2);

    for DOMAIN_NAME in $domainlist; do
#        HOST_ADDED=$(grep 'local.$DOMAIN_NAME' /etc/hosts | wc -l)
#        if [ $HOST_ADDED -lt 1 ]; then
#            echo "127.0.0.1 local.$DOMAIN_NAME" >> /etc/hosts
#        fi

        DB_NAME=$(grep 'DB_NAME=' ${SETUP_QUEUE}/${DOMAIN_NAME}.txt | cut -d'=' -f2 )

        rm ${SETUP_QUEUE}/${DOMAIN_NAME}.txt

#        DOMAIN_ADDED=$(grep 'Domain addition completed' ${STATUS_QUEUE}/${DOMAIN_NAME}.txt | wc -l)
#        if [ $DOMAIN_ADDED -lt 1 ]; then

          if [[ -n "$DOMAIN_NAME" && -n "$DB_NAME" ]]; then
            echo "" > ${STATUS_QUEUE}/${DOMAIN_NAME}.txt;
             /bin/bash -c "/setup-domain.sh add $DOMAIN_NAME $DB_NAME &> ${STATUS_QUEUE}/${DOMAIN_NAME}.txt";
          else
            echo "Failed to provide domain name: $DOMAIN_NAME or db name: $DB_NAME" > ${STATUS_QUEUE}/${DOMAIN_NAME}.txt;
          fi

#        else
#            echo "Domain already added";
#        fi

        rm ${STATUS_QUEUE}/${DOMAIN_NAME}.txt

    done

sleep 20s