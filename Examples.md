
# Yobi HTTP - Usage examples

Some examples of using the 

Some examples of using the Yobi HTTP CLI.

## Simple HTTP Get request

```bash
yobi --debug https://httpbin.org/get
```

## HTTP POST request with JSON body

```bash
yobi --debug POST https://httpbin.org/post name=Yobi type="HTTP client"
```

## WIP: HTTP POST request with form data

```bash
yobi --debug POST https://httpbin.org/post name=Yobi type="HTTP client" --form
```

## HTTP request with query parameters

```bash
yobi --debug https://httpbin.org/get name=Yobi type="HTTP client"
```
## HTTP request with basic authentication

```bash
yobi --debug https://httpbin.org/basic-auth/user/passwd --auth user:passwd --auth-type basic
```

## HTTP request with timeout

```bash
yobi --debug --timeout 5 https://httpbin.org/delay/10
```

## HTTP request with custom headers

```bash
yobi --debug https://httpbin.org/headers X-Custom-Header:Yobi User-Agent:"Yobi HTTP Client"
```

## Download a file

```bash
yobi --debug --download https://ash-speed.hetzner.com/100MB.bin -o sample.bin
```

## HTTP request with follow redirects

```bash
yobi --debug --follow https://httpbin.org/redirect/3
```

## HTTP request with output to a file

```bash
yobi -p B https://httpbin.org/get -o response.json
```

## HTTP request with verbose output

```bash
yobi --debug --verbose https://httpbin.org/get
```

