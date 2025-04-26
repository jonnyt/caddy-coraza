# caddy-coraza

This will build Caddy with the Coraza WAF.  The included configuration will
run on port 80 and implements the recommended OWASP sec policy.

## building

Builds using the caddy builder image to add the Coraza plugin.  See `build_and_run.sh`.

## configuration

- `order coraza_waf first` must be the first global directive for Caddy
- `coraza.conf` should be loaded before the standard rulesets especially when overriding vars like `tx.allowed_methods`
- `coraza_waf` block can be added to any site
- `load_owasp_crs` automatically loads the ModSecurity Core Rule Set (CRS)
= `directives` includes various defaults, but they are in report-only mode so set `SecRuleEngine On` at the end


## testing

```shell
./build_and_run.sh
curl -v "http://localhost/?q=%3Cscript%3Ealert(1)%3C%2Fscript%3E"
curl -v "http://localhost/?id=1%20UNION%20SELECT%20password%20FROM%20users"
curl -v http://localhost/\?q\=select+from
```