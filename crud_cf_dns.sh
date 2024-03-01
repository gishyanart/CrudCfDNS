#!/bin/bash

set -o pipefail -o errtrace -o errexit

on_failure() {
  echo -e "\n\tUnxexpected error in line: $1"
}

trap 'on_failure ${LINENO}' ERR

REC_TYPE="A"
TTL="1"
AUTH_TYPE="TOKEN"
AUTH_SET="FALSE"
PROXIED="true"
PRETTY="true"
FILTER=""
COMMENT=""
OUTPUT_FORMAT="j"

CONFIG_FILE="${HOME}/.config/crud_cf_dns.vars"
# shellcheck source=/dev/null
[ -s "${CONFIG_FILE}" ] && source "${CONFIG_FILE}" &>/dev/null

RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
RESET="\033[00m"

crud_dns_rec_test () {
  case ${COMMAND} in
  CREATE)
    echo curl -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records"
    [ "${AUTH_TYPE}" = "KEY" ] && echo -H "X-Auth-Email: ${EMAIL}"
    echo -H "${AUTH}"
    echo -H "Content-Type: application/json"
    echo --data "{\"type\":\"${REC_TYPE}\",\"name\":\"${REC_NAME}\",\"content\":\"${REC_CONT}\",\"ttl\":${TTL},\"priority\":10,\"proxied\":${PROXIED}, \"comment\": \"${COMMENT}\"}"
     ;;
  READ)
    echo curl -X GET  "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records?name=${REC_NAME}"
    [ "${AUTH_TYPE}" = "KEY" ] && echo -H "X-Auth-Email: ${EMAIL}"
    echo -H "${AUTH}"
    echo -H "Content-Type: application/json"
    ;;
  UPDATE)
    echo curl -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records/${REC_ID}"
    [ "${AUTH_TYPE}" = "KEY" ] && echo -H "X-Auth-Email: ${EMAIL}"
    echo -H "${AUTH}"
    echo -H "Content-Type: application/json"
    echo --data "{\"type\":\"${REC_TYPE}\",\"name\":\"${REC_NAME}\",\"content\":\"${REC_CONT}\",\"ttl\":${TTL},\"proxied\":${PROXIED}, \"comment\": \"${COMMENT}\"}"
    ;;
  DELETE)
    echo curl -X DELETE "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records/${REC_ID}"
    [ "${AUTH_TYPE}" = "KEY" ] && echo -H "X-Auth-Email: ${EMAIL}"
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
     --data "{\"type\":\"${REC_TYPE}\",\"name\":\"${REC_NAME}\",\"content\":\"${REC_CONT}\",\"ttl\":${TTL},\"priority\":10,\"proxied\":${PROXIED}, \"comment\": \"${COMMENT}\"}"
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
     --data "{\"type\":\"${REC_TYPE}\",\"name\":\"${REC_NAME}\",\"content\":\"${REC_CONT}\",\"ttl\":${TTL},\"proxied\":${PROXIED}, \"comment\": \"${COMMENT}\"}"
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

configure_creds() {
  local zone_name
  local zone_name_conf
  local zone_id
  local secret
  local email
  local answer
  read -r -p "    Enter the zone name ( example.com ): " zone_name
  if ! ( grep -E '^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)+[a-zA-Z]{2,}\.?$' <<<"${zone_name}" &>/dev/null )
  then
    echo "    ${zone_name} is not a valid DNS name (e.g. example.com)"
    exit 1
  fi

  ( grep '\.$' <<<"${zone_name}" &> /dev/null ) && zone_name="${zone_name:0:-1}"
  zone_name_conf=$(awk -F'_' '{print $(NF-1)"_"$NF }' <<<"${zone_name//./_}" )

  if ( grep "${zone_name_conf}" "${CONFIG_FILE}" &>/dev/null)
  then
    read -r -p "    Found existing configuration. Overwrite? [y/n]: " answer
    case "${answer,,}" in
      y)
        sed -i "/${zone_name}/d" "${CONFIG_FILE}"
        ;;
      n)
        exit 0
        ;;
      *)
        echo -e "\n\t ${RED}Wrong input: Enter [Yy] or [Nn] ${RESET}\n"
        exit 47
    esac
  fi
  read -r -p "    Enter the zone ID (like. 12fc7ceddcf1f8d547bdf604ca69a24c): " zone_id
  read -r -p "    What auth type use for this zone? API key/token [k/t]: " answer
  case "${answer,,}" in
    k)
      read -ers -p "    Enter the API key: " secret
      read -r -p   "    Enter the Email address: " email
      answer="KEY"
      echo "declare -gA ${zone_name_conf}=( [id]=${zone_id} [secret]=${secret} [email]=${email} [auth]=${answer} )" >> "${CONFIG_FILE}"
      ;;
    t)
      read -r -s -p "    Enter the API token: " secret
      echo
      answer="TOKEN"
      echo "declare -gA ${zone_name_conf}=( [id]=${zone_id} [secret]=${secret} [auth]=${answer} )" >> "${CONFIG_FILE}"
      ;;
    *)
      echo -e "\n\t ${RED}Wrong input: Enter [Kk] or [Tt]${RESET}\n"
      exit 47
  esac

  exit 0
}


delete() {
  local name
  local exist
  [ -z "$1" ] && { echo -e "\n\t${RED}Empty Zone name to delete\n${RESET}"; exit 1; }
  name=$(awk -F'_' '{print $(NF-1)"_"$NF }' <<<"${1//./_}" )
  ( grep "${name}" "${CONFIG_FILE}" &>/dev/null ) || { echo -e "${RED}\n\t Nothing to delete\n${RESET}"; exit 1; }
  sed -i "/${name}/d" "${CONFIG_FILE}" &>/dev/null
  exit 1
}

set_defaults() {
  local zone_var
  local zone_name
  local normalized
  ( grep "\.$" <<< "$1" ) && normalized="${1:0:-1}" || normalized=$1
  zone_name=$(awk -F'_' '{print $(NF-1)"_"$NF }' <<<"${normalized//./_}" )
  declare -n zone_var="${zone_name}"
  [ -z "${zone_name}" ]  && return
  [ -z "${CF_ZONE}"   ]  && CF_ZONE="${zone_var[id]}"
  [ -z "${SECRET}"    ]  && SECRET="${zone_var[secret]}"
  [ -z "${EMAIL}"     ]  && EMAIL="${zone_var[email]}"

  if [ "${AUTH_SET}" = "TRUE" ] || [ "${zone_var[auth]}" = "KEY" ]
  then
    AUTH_TYPE="${zone_var[auth]}"
  fi
}

show() {
  local names
  local email
  local zone_name
  local array
  if ! [ -e "${CONFIG_FILE}" ]
  then
    echo -e "${RED}\n\tMissing config file: ${CONFIG_FILE}${RESET}\n"
    exit 1
  elif ! [ -s "${CONFIG_FILE}" ]
  then
    echo -e "${RED}\n\tConfig file is empty. Nothing to show. Use set command to crate configs.${RESET}\n"
    exit 1
  fi

  if [ -n "$1" ] && ! ( grep -E '^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)+[a-zA-Z]{2,}\.?$' <<<"$1" &>/dev/null )
  then
    echo -e "\n\t$1 is not a valid DNS name\n"
    exit 1
  elif [ -z "$1" ]
  then
    mapfile -t names <<<"$(awk '{print $3}' "${CONFIG_FILE}" | awk -F'=' '{print $1}')"
    exist=1
  else
    ( grep '\.$' <<<"$1" &> /dev/null ) && zone_name="${zone_name:0:-1}" || zone_name="$1"
    zone_name=$(echo "${zone_name//./_}" | awk -F'_' '{print $(NF-1)"_"$NF }' )
    mapfile -t names <<<"$(grep "${zone_name}" "${CONFIG_FILE}" | awk '{print $3}' | awk -F'=' '{print $1}')"
  fi

  if [ ! "$exist" ]
  then
    for i in "${names[@]}"
    do
      if [ "$i" = "$zone_name" ]
      then
        exist=1
        break
      fi
    done
  fi
  if ! [ "$exist" ]
  then
    echo -e "\n\t${RED}Config for \`${1}\` does not exist${RESET}\n"
    exit 1
  fi
  [ -z "${names[*]}" ] && { echo -e "${RED}\n\tNo configuration found.\n${RESET}"; exit 0; }
  for name in "${names[@]}"
  do
    declare -n array="${name}"
    if [ -z "${array[email]}" ]
    then
      echo -e "${GREEN}[${name//_/.}]\n\tid=${array[id]}\n\tsecret=${array[secret]}\n\tauth-type=${array[auth]}${RESET}"
    else
      echo -e "${GREEN}[${name//_/.}]\n\tid=${array[id]}\n\tsecret=${array[secret]}\n\temail=${array[email]}\n\tauth-type=${array[auth]}${RESET}"
    fi
  done
  exit 0
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
        missing record name, specify with -n
    "
  elif ! ( grep -E '^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)+[a-zA-Z]{2,}\.?$' <<<"${REC_NAME}" &>/dev/null )
  then
    err="${err}
        invalid record name, must be valid DNS name ( example.com, app.example.com ...)
    "
  else
    set_defaults "${REC_NAME}"
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

  Commands: { run | test | set | delete ZONE | show [ZONE] }
    run         : cloudflare api call with curl
    test        : print api call curl command
    set         : create/edit configuration file
    delete ZONE : delete DNS zone configs ( One config per execution )
    show        : show default configurations
                  default is print all configs
                  specify ZONE name to show only for that zone

  Options and arguments for run and test commands:
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
    -i          : CLoudFlare record comment
    -k          : set authorization type to api key
                  default is token
    -s          : api key or token value
    -m          : X-Auth-Email (ex. user@example.com)
                  must be passed with api key authorization
    -j          : disable pretty print
    -f          : yq filter (ex. -f "-r .result[0].content" )
                  note. use double quotes to avoid conflicts with script options
    -o          : Output format (default is json). Valid values are: y/yaml or j/json.
                  All other values will be ignored.
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
  set)
    configure_creds
    ;;
  show)
    shift
    show "$1"
    ;;
  delete)
    shift
    delete "$1"
    ;;
  '-h')
    shift
    usage
    exit
    ;;
  *)
    echo -e "\n${RED}Wrong input${RESET}"
    usage
    exit 1
    ;;
esac

while getopts "crudhjt:n:b:l:z:ks:m:p:f:i:o:" option; do
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
          ( grep "\.$" <<< "$REC_NAME" ) && REC_NAME="${REC_NAME:0:-1}"
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
        i)
          COMMENT=${OPTARG}
          ;;
        o)
          case "${OPTARG}" in
            y)
              OUTPUT_FORMAT=y
            ;;
            yaml)
              OUTPUT_FORMAT=y
            ;;
            j)
              OUTPUT_FORMAT=j
            ;;
            json)
              OUTPUT_FORMAT=j
            ;;
            *)
              OUTPUT_FORMAT=j
            ;;
          esac
          ;;
        h)
          usage
          exit 0
          ;;
        j)
          [ -n "${FILTER}" ] && echo -e "\n\t${GREEN}yq filter is specified pretty print disabling will be ignored.${RESET}\n" || PRETTY="false"
          echo "${FILTER}"
          ;;
        f)
          FILTER="${OPTARG}"
          ;;
        *)
          usage
          exit 1
          ;;
    esac
done
shift $((OPTIND-1))

check_opts
set_auth_body

if [ "${COMMAND}" != "CREATE" ] && [ "${COMMAND}" != "READ" ]
then
  RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records?name=${REC_NAME}" \
     -H "X-Auth-Email: ${EMAIL}" \
     -H "${AUTH}" \
     -H "Content-Type: application/json")
  _success="$(yq -roj .success <<< "$RESPONSE")"
  if [ "${_success}" != "true" ]
  then
    echo -e "${RED} Failed to get record ids for ${YELLOW}${REC_NAME}${RESET}"
    exit 1
  fi
  length="$(yq '.result | length' <<< "$RESPONSE")"
  if [ "$length" -gt 1 ]
  then
    mapfile -t _contents <<< "$(yq -roy '.result[] | .content' <<< "$RESPONSE")"
    echo -e "\n${BLUE}Found more than 1 record for ${GREEN}${REC_NAME}:${RESET}"
    yq -roy '.result[] | [{"id": .id, "value": .content, "type": .type}]' <<< "$RESPONSE"
    PS3="Select the record: "
    select _content in "${_contents[@]}"
    do
      break
    done
  fi
  REC_ID=$(CONTENT="${_content}" yq -roy '.result[] | select(.content == env(CONTENT)) | .id' <<< "$RESPONSE")
fi

RESPONSE=$(${run})
if [ "${run}" = "crud_dns_rec" ]
then
  case "${PRETTY}" in
    true)
      if [ "$FILTER" ]
      then
        echo "${RESPONSE}" | yq "$FILTER" -Po${OUTPUT_FORMAT}
      else
        echo "${RESPONSE}" | yq -Po${OUTPUT_FORMAT}
      fi
      ;;
    false)
      echo "${RESPONSE}"
      echo
      ;;
    *)
      ;;
  esac
else
  echo "${RESPONSE}"
fi
