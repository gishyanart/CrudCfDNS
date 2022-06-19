FROM curlimages/curl

USER root

RUN apk add jq bash

COPY crud_cf_dns.sh /bin/

COPY cf_rec.sh /bin/

ENTRYPOINT ["/bin/cf_rec.sh"]

