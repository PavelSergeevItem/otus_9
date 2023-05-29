#!/bin/bash
LOCK_FILE=/var/tmp/myscript.lock
if [ -e ${LOCK_FILE} ] && kill -0 `cat ${LOCK_FILE}`; then
  echo "uge rabotaet"
  exit
fi

trap "rm -f ${LOCK_FILE}; exit" INT TERM EXIT

echo $$ > ${LOCK_FILE}

LOG_FILE=/var/log/httpd/access_log
EMAIL_TO="ps@item.expert"
SUBJECT="otchet"

#vremia
LAST_RUN="$(stat -c %Y $0)"
CURRENT_TIME="$(date +%s)"
DIFF_TIME=$((CURRENT_TIME-LAST_RUN))
START_TIME="$(date -d 'today 00:00:00' '+%s')"
END_TIME="$(date -d '1 hour ago' '+%s')"

#otchet
TOP_IP=$(awk -v start=$START_TIME -v end=$END_TIME '{ if ($4 > start && $4 < end) {print $1} }' ${LOG_FILE} | sort | uniq -c | sort -nr | head -n 10)
TOP_URL=$(awk -v start=$START_TIME -v end=$END_TIME '{ if ($4 > start && $4 < end) {print $7} }' ${LOG_FILE} | sort | uniq -c | sort -nr | head -n 10)
ERRORS=$(grep -iE '(404|500|503)' ${LOG_FILE} | awk -v start=$START_TIME -v end=$END_TIME '{ if ($4 > start && $4 < end) {print $1 " -- " $7 " -- " $9} }')
HTTP_CODES=$(awk -v start=$START_TIME -v end=$END_TIME '{ if ($4 > start && $4 < end) {print $9} }' ${LOG_FILE} | sort | uniq -c)

#pismo

cat << EOF | mail -s "${SUBJECT}" "${EMAIL_TO}"
	vremennoy promegutok:$(date -d '1 hour ago' '+%F %T') -- $(date '+%F %T')
	spisok ip:${TOP_IP} spisok url:${TOP_URL}
	spisok oshibok:${ERRORS} 	
	spisok http otvetov:${HTTP_CODES}
EOF

rm -f ${LOCK_FILE}
