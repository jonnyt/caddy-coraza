# caddy-coraza

This will build Caddy with the Coraza WAF.  The included configuration will
run on port 80 and implements the recommended OWASP sec policy.

## building




## testing

```shell
curl -v "http://localhost/?q=%3Cscript%3Ealert(1)%3C%2Fscript%3E"
curl -v "http://localhost/?id=1%20UNION%20SELECT%20password%20FROM%20users"
curl -v http://localhost/\?q\=select+from
```