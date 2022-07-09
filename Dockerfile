FROM curlimages/curl

USER root

RUN apk add jq bash

COPY crud_cf_dns.sh /bin/

COPY crud_cf_dns.vars /root/.config/

ENTRYPOINT ["/bin/crud_cf_dns.sh"]
