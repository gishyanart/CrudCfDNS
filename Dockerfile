FROM curlimages/curl

USER root

RUN apk add jq bash

COPY crud_cf_dns.sh /bin/

COPY crud_cf_dns.vars /home/curl_user/.config/

ENTRYPOINT ["/bin/crud_cf_dns.sh"]
