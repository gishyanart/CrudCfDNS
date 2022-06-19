#!/bin/sh

set -e

REC_TYPE="A"
TTL="1"
AUTH_TYPE="TOKEN"

crud_dns_rec_test () {
  case ${COMMAND} in 
  CREATE)
    echo "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records" 
    echo -H "X-Auth-Email: ${EMAIL}" 
    echo -H "${AUTH}" 
    echo -H "Content-Type: application/json" 
    echo --data "{\"type\":\"${REC_TYPE}\",\"name\":\"${REC_NAME}\",\"content\":\"${REC_CONT}\",\"ttl\":${TTL},\"priority\":10,\"proxied\":${PROXY_STATUS}}"
     ;;
  READ)
    echo "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records?name=${REC_NAME}" 
    echo -H "X-Auth-Email: ${EMAIL}" 
    echo -H "${AUTH}" 
    echo -H "Content-Type: application/json"
    ;;
  UPDATE)
    echo "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records/${REC_ID}" 
    echo -H "X-Auth-Email: ${EMAIL}" 
    echo -H "${AUTH}" 
    echo -H "Content-Type: application/json" 
    echo --data "{\"type\":\"${REC_TYPE}\",\"name\":\"${REC_NAME}\",\"content\":\"${REC_CONT}\",\"ttl\":${TTL},\"proxied\":${PROXY_STATUS}}"
    ;;
  DELETE)
    echo "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records/${REC_ID}" 
    echo -H "X-Auth-Email: ${EMAIL}" 
    echo -H "${AUTH}"  
    echo -H "Content-Type: application/json"
    ;;
  *)
    echo "Unrecognized command"
    exit 1
    ;;
  esac
}

crud_dns_rec() {
  case ${COMMAND} in 
  CREATE)
    curl -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records" \
     -H "X-Auth-Email: ${EMAIL}" \
     -H "${AUTH}" \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"${REC_TYPE}\",\"name\":\"${REC_NAME}\",\"content\":\"${REC_CONT}\",\"ttl\":${TTL},\"priority\":10,\"proxied\":${PROXY_STATUS}}"
     ;;
  READ)
    curl -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records?name=${REC_NAME}" \
     -H "X-Auth-Email: ${EMAIL}" \
     -H "${AUTH}" \
     -H "Content-Type: application/json"
    ;;
  UPDATE)
    curl -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records/${REC_ID}" \
     -H "X-Auth-Email: ${EMAIL}" \
     -H "${AUTH}" \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"${REC_TYPE}\",\"name\":\"${REC_NAME}\",\"content\":\"${REC_CONT}\",\"ttl\":${TTL},\"proxied\":${PROXY_STATUS}}"
    ;;
  DELETE)
    curl -X DELETE "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records/${REC_ID}" \
     -H "X-Auth-Email: ${EMAIL}" \
     -H "${AUTH}"  \
     -H "Content-Type: application/json"
    ;;
  *)
    echo "Unrecognized command"
    exit 1
    ;;
  esac
}

set_auth_body() {
  case "${AUTH_TYPE}" in
    KEY)
      AUTH="\"X-Auth-Key: ${SECRET}\""
      ;;
    TOKEN)
      AUTH="\"Authorization: Bearer ${SECRET}\""
      ;;
    *)
      echo "Failure"
      exit 3
      ;;
  esac
}

check_opts() {
  err="Error: "
  help="
    Specify:
  "
  if [ "${COMMAND}" = "" ]
  then
    err="${err} operation method"
    help="${help}
        method with -c,-r,-u,-d : create,read,update,delete record
    "
  elif [ "${REC_NAME}" = "" ]
  then
    err="${err},record name"
    help="${help}
        record name with -n option
    "
  elif [ "${REC_CONT}" = "" ]
  then
    err="${err},record content"
    help="${help}
        record content with -b option
    "
  elif [ "${CF_ZONE}" = "" ]
  then
    err="${err},cloudflare zone"
    help="${help}
        cloudflare zone with -z option
    "
  elif [ "${SECRET}" = "" ]
  then
    err="${err}, api secret"
    help="${help}
        api secret with -s option
    "
  elif [ "${AUTH_TYPE}" = "KEY" ] && [ "${EMAIL}" = "" ]
  then
    err="${err}, email"
    help="${help}
        with api key email must be passed, use -m option
    "
  fi

  if [ "${err}" != "Error: " ]
  then
    echo "${err}"
    echo "${help}
        to see all options run: crud_cf_dns.sh -h
    "
    exit 2
  fi
}



usage() {
echo "
  crud_cf_dns.sh: Create,Read,Update,Delete CloudFlare DNS record for Zone.
  
  Options and arguments:
    -c,-r,-u,-d : create,read,update,delete record
    -t          : record type (A,CNAME,TXT etc.)
                  default is A
    -n          : name of the record (ex. example.com)
    -b          : record content (ex. 127.0.0.1)
    -l          : ttl of the record,
                  must be between 60 and 86400,
                  or 1 for automatic (default value)
    -z          : DNS zone ID
    -k          : set authorization type to api key
                  default is token
    -s          : api key or token value
    -m          : X-Auth-Email (ex. user@example.com)
                  must be passed with api key authorization
    -h          : Print this message
"
}

while getopts "crudth:n:b:l:z:ks:m:" option; do
    case "${option}" in
        c)
          COMMAND="CREATE"
          ;;
        r) 
          COMMAND="READ"
          ;;
        u)
          COMMAND="UPDATE"
          ;;
        d)
          COMMAND="DELETE"
          ;;
        t)
          REC_TYPE=${OPTARG};
          ;;
        n)
          REC_NAME=${OPTARG};
          ;;
        b)
          REC_CONT=${OPTARG};
          ;;
        l)
          TTL=${OPTARG}
          ;;
        z)
          CF_ZONE=${OPTARG}
          ;;
        k)
          AUTH_TYPE="KEY"
          ;;
        s)
          SECRET=${OPTARG}
          ;;
        m)
          EMAIL=${OPTARG}
          ;;
        h)
          usage
          exit 0
          ;;
        *)
          echo "Invalid option passed: ${option}"
          usage
          exit 1
          ;;
    esac
done
shift $((OPTIND-1))

check_opts

set_auth_body

crud_dns_rec_test