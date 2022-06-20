#!/bin/bash

set -e

REC_TYPE="A"
TTL="1"
AUTH_TYPE="TOKEN"
PROXIED="true"

crud_dns_rec_test () {
  case ${COMMAND} in 
  CREATE)
    echo curl -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records" 
    echo -H "X-Auth-Email: ${EMAIL}" 
    echo -H "${AUTH}" 
    echo -H "Content-Type: application/json" 
    echo --data "{\"type\":\"${REC_TYPE}\",\"name\":\"${REC_NAME}\",\"content\":\"${REC_CONT}\",\"ttl\":${TTL},\"priority\":10,\"proxied\":${PROXIED}}"
     ;;
  READ)
    echo curl -X GET  "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records?name=${REC_NAME}" 
    echo -H "X-Auth-Email: ${EMAIL}" 
    echo -H "${AUTH}" 
    echo -H "Content-Type: application/json"
    ;;
  UPDATE)
    echo curl -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records/${REC_ID}" 
    echo -H "X-Auth-Email: ${EMAIL}" 
    echo -H "${AUTH}" 
    echo -H "Content-Type: application/json" 
    echo --data "{\"type\":\"${REC_TYPE}\",\"name\":\"${REC_NAME}\",\"content\":\"${REC_CONT}\",\"ttl\":${TTL},\"proxied\":${PROXIED}}"
    ;;
  DELETE)
    echo curl -X DELETE "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records/${REC_ID}" 
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
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records" \
     -H "X-Auth-Email: ${EMAIL}" \
     -H "${AUTH}" \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"${REC_TYPE}\",\"name\":\"${REC_NAME}\",\"content\":\"${REC_CONT}\",\"ttl\":${TTL},\"priority\":10,\"proxied\":${PROXIED}}"
     ;;
  READ)
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records?name=${REC_NAME}" \
     -H "X-Auth-Email: ${EMAIL}" \
     -H "${AUTH}" \
     -H "Content-Type: application/json"
    ;;
  UPDATE)
    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records/${REC_ID}" \
     -H "X-Auth-Email: ${EMAIL}" \
     -H "${AUTH}" \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"${REC_TYPE}\",\"name\":\"${REC_NAME}\",\"content\":\"${REC_CONT}\",\"ttl\":${TTL},\"proxied\":${PROXIED}}"
    ;;
  DELETE)
    curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records/${REC_ID}" \
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
      AUTH="X-Auth-Key: ${SECRET}"
      ;;
    TOKEN)
      AUTH="Authorization: Bearer ${SECRET}"
      ;;
    *)
      echo "Failure"
      exit 3
      ;;
  esac
}

check_opts() {
  err="    Error: following argument(s) not passed or invalid
  "
  if [ "${COMMAND}" = "" ]
  then
    err="${err}
        operation method, specify with -c,-r,-u,-d
    "
  fi
  if [ "${REC_NAME}" = "" ]
  then
    err="${err}
        record name, specify with -n
    "
  fi
  if [ "${COMMAND}" != "READ" ] && [ "${COMMAND}" != "DELETE" ] && [ "${REC_CONT}" = "" ]
  then
    err="${err}
        record content, specify with -b
    "
  fi
  if [ "${CF_ZONE}" = "" ]
  then
    err="${err}
        cloudflare zone, specify with -z
    "
  fi
  if [ "${SECRET}" = "" ]
  then
    err="${err}
        api secret, specify with -s
    "
  fi
  if [ "${AUTH_TYPE}" = "KEY" ] && [ "${EMAIL}" = "" ]
  then
    err="${err}
        email, specify with -m, required with -k option
    "
  fi
  if [ "${PROXIED}" != "true" ] && [ "${PROXIED}" != "false" ]
  then
    err="${err}
        proxy status can be only true or false, passed value is \"${PROXIED}\"
    "
  fi

  local valid
  local types=(A AAAA CNAME HTTPS TXT SRV LOC MX NS CERT DNSKEY DS NAPTR SMIMEA SSHFP SVCB TLSA URI)
  for i in "${types[@]}"
  do
    if [ "${REC_TYPE}" =  "$i" ]
    then
      valid=true
      break
    fi
  done
  if ! [ "${valid}" == "true" ]
  then
    err="${err}
        record type is invalid, valid types are
        \"${types[*]}\"
    "
  fi

  if [ "${err}" != "    Error: following argument(s) not passed or invalid
  "  ]
  then
    echo ""
    echo "${err}
    To see all options run: crud_cf_dns.sh -h
    "
    exit 2
  fi
}



usage() {
echo "
  crud_cf_dns.sh: Create,Read,Update,Delete CloudFlare DNS record for Zone.
  
  Commands: { run | test }
    run         : cloudflare api call with curl
    test        : print api call curl command 

  Options and arguments:
    -c,-r,-u,-d : create,read,update,delete record
    -t          : record type (A,CNAME,TXT etc.)
                  default is A
    -n          : name of the record (ex. example.com)
    -b          : record content (ex. 127.0.0.1)
    -l          : ttl of the record,
                  must be between 60 and 86400,
                  or 1 for automatic (default value)
    -p          : set proxy status true or false
                  default value is true
    -z          : DNS zone ID
    -k          : set authorization type to api key
                  default is token
    -s          : api key or token value
    -m          : X-Auth-Email (ex. user@example.com)
                  must be passed with api key authorization
    -h          : Print this message
"
}

case "$1" in
  test)
    shift
    run=crud_dns_rec_test
    ;;
  run)
    shift
    run=crud_dns_rec
    ;;
  *)
    usage
    exit 1
    ;;
esac

while getopts "crudht:n:b:l:z:ks:m:p:" option; do
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
        p)
          PROXIED=${OPTARG}
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
          usage
          exit 1
          ;;
    esac
done
shift "$(expr ${OPTIND} - 1)"

check_opts

set_auth_body

if [ "${COMMAND}" != "CREATE" ] && [ "${COMMAND}" != "READ" ]
then
  REC_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records?name=${REC_NAME}" \
     -H "X-Auth-Email: ${EMAIL}" \
     -H "${AUTH}" \
     -H "Content-Type: application/json" | jq -r .result[])
  if [ "${REC_ID}" = "" ]
  then
    echo "${REC_NAME} record not exist"
    exit 1
  else
    REC_ID=$(echo "${REC_ID}" | jq -r .id )
  fi
fi

${run}