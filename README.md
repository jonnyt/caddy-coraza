# caddy-coraza

This will build Caddy with the Coraza WAF.  The included configuration will
run on port 80 and implements the recommended OWASP sec policy.

## Building

Builds using the caddy builder image to add the Coraza plugin.  See `build_and_run.sh`.

## Configuration

- `order coraza_waf first` must be the first global directive for Caddy
- `coraza.conf` should be loaded before the standard rulesets especially when overriding vars like `tx.allowed_methods`
- `coraza_waf` block can be added to any site
- `load_owasp_crs` automatically loads the ModSecurity Core Rule Set (CRS)
= `directives` includes various defaults, but they are in report-only mode so set `SecRuleEngine On` at the end

### Overriding Specific Variables

Variables found within the (coraza.conf-recommended)[https://github.com/corazawaf/coraza/blob/main/coraza.conf-recommended] can be overridden either using `directives` or loading a configuraiton file.

This should be done after loading the recommend configuration and before applying rulesets.

For example, the default configuration variable `tx.allowed_methods` only permits `GET HEAD POST OPTIONS`.  If we need to allow additional HTTP methods globally we can define this rule:

```
SecAction \
    "id:900200,\
    phase:1,\
    pass,\
    t:none,\
    nolog,\
    tag:'OWASP_CRS',\
    ver:'OWASP_CRS/4.14.0-dev',\
    setvar:'tx.allowed_methods=GET HEAD POST OPTIONS PUT PATCH DELETE'"
```

Or as a rule with a location matcher:

```
SecRule REQUEST_URI "@beginsWith /api/system-config" \
    "id:900200,\
    phase:1,\
    pass,\
    t:none,\
    nolog,\
    tag:'OWASP_CRS',\
    ver:'OWASP_CRS/4.14.0-dev',\
    setvar:'tx.allowed_methods=GET HEAD POST OPTIONS PUT PATCH DELETE'"
```

### Overriding Specific Rules

If Coraza breaks an application we can override the default ruleset.

In this example the WAF is blocking file access to `.profile` at our endpoint `/api/system-config`:

```json
{
    "level": "error",
    "ts": 1745770573.738763,
    "logger": "http.handlers.waf",
    "msg": "[client \"192.168.1.1\"] Coraza: Warning. OS File Access Attempt [file \"@owasp_crs/REQUEST-930-APPLICATION-ATTACK-LFI.conf\"] [line \"3114\"] [id \"930120\"] [rev \"\"] [msg \"OS File Access Attempt\"] [data \"Matched Data: .profile found within ARGS_NAMES:json.oauth.profileSigningAlgorithm: json.oauth.profileSigningAlgorithm\"] [severity \"critical\"] [ver \"OWASP_CRS/4.7.0\"] [maturity \"0\"] [accuracy \"0\"] [tag \"application-multi\"] [tag \"language-multi\"] [tag \"platform-multi\"] [tag \"attack-lfi\"] [tag \"paranoia-level/1\"] [tag \"OWASP_CRS\"] [tag \"capec/1000/255/153/126\"] [tag \"PCI/6.5.4\"] [hostname \"\"] [uri \"/api/system-config\"] [unique_id \"vkxkeIqsiEVrGnLl\"]"
}
```

We can turn the rule off globally adding the following line toward the end of our ruleset:

```
SecRuleUpdateActionById 930120 "nolog,pass,ctl:ruleRemoveById=930120"
````

Where:

- `nolog,pass` = don't log and allow
- `ctl:ruleRemoveById=930120` = remove the rule

We can also be more specific and just disable the rule for a specific endpoint.  If we want to permit access to `/api/system-config` or any other endpoint we can use a location matcher:

```
SecRule REQUEST_URI "@beginsWith /api/system-config" \
    "id:1000000,phase:1,pass,nolog,ctl:ruleRemoveById=930120"
```

And add this to `directvies` or a configuration file:

```
directives `
Include @coraza.conf-recommended
Include /etc/caddy/coraza.conf
Include @crs-setup.conf.example
Include @owasp_crs/*.conf
# Allow file access for Immich API for admin / configuration settings
SecRule REQUEST_URI "@beginsWith /api/system-config" "id:1000000,phase:1,pass,nolog,ctl:ruleRemoveById=930120"
SecRuleEngine On
`
```

## Testing

```shell
./build_and_run.sh
curl -v "http://localhost/?q=%3Cscript%3Ealert(1)%3C%2Fscript%3E"
curl -v "http://localhost/?id=1%20UNION%20SELECT%20password%20FROM%20users"
curl -v http://localhost/\?q\=select+from
```

## Reference

- (ModSecurity Reference)[https://github.com/owasp-modsecurity/ModSecurity/wiki/Reference-Manual-(v3.x)#user-content-SecAction]