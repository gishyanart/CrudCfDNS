# CrudCfDNS

Manage CloudFlare DNS records for zone

## Usage

```text
  crud_cf_dns.sh: Create,Read,Update,Delete CloudFlare DNS record for Zone.
  
  Commands: { run | test | set | delete ZONE | show [ZONE] }
    run         : cloudflare api call with curl
    test        : print api call curl command 
    set         : create/edit configuration file
    delete ZONE : delete DNS zone configs
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
    -k          : set authorization type to api key
                  default is token
    -s          : api key or token value
    -m          : X-Auth-Email (ex. user@example.com)
                  must be passed with api key authorization
    -h          : Print this message
```

## Dependencies

- [tput](https://www.gnu.org/software/termutils/manual/termutils-2.0/html_chapter/tput_1.html#SEC1)

- [jq](https://stedolan.github.io/jq/)

- [curl](https://curl.se/)

## Config File

Configuration file is `bash` source file with associative array declarations. If this file exists script will `source` it. Location is `~/.config/crud_cf_dns.vars`.

```text
>> cat ~/.config/crud_cf_dns.vars
declare -gA example_com=( [id]=1x... [secret]=Gd... [auth]=TOKEN )
declare -gA example_dev=( [id]=2y... [secret]=Fe... [email]=user@example.com [auth]=KEY )
```

> Execution Example.

```text
>> crud_cf_dns.sh run -r -n example.dev
>> crud_cf_dns.sh run -c -n dev.example.com -t CNAME -t 180 -p false -b app.example.com -s c4b... -z ZpG... 

>> crud_cf_dns.sh test -r -n example.dev
curl -X GET https://api.cloudflare.com/client/v4/zones/2y.../dns_records?name=example.dev
-H X-Auth-Email: user@example.com
-H X-Auth-Key: Fe...
-H Content-Type: application/json

>> crud_cf_dns.sh test -c -n dev.example.com -t CNAME -l 180 -p false -b app.example.com
curl -X POST https://api.cloudflare.com/client/v4/zones/1x.../dns_records
-H Authorization: Bearer Gd...
-H Content-Type: application/json
--data {"type":"CNAME","name":"dev.example.com","content":"app.example.dev","ttl":180,"priority":10,"proxied":false}

>> crud_cf_dns.sh show
[example.com]
  id=1x...
  secret=Gd...
  auth-type=TOKEN
[example.dev]
  id=2y...
  secret=Fe...
  email=user@example.com
  auth-type=KEY

```
