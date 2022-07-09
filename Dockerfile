FROM curlimages/curl

USER root

RUN apk add jq bash

COPY crud_cf_dns.sh /bin/

ENTRYPOINT ["/bin/crud_cf_dns.sh"]