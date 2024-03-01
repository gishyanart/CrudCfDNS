FROM curlimages/curl:8.6.0

USER root

RUN apk add yq bash

COPY crud_cf_dns.sh /bin/

COPY crud_cf_dns.vars /home/curl_user/.config/

ENTRYPOINT ["/bin/crud_cf_dns.sh"]
