
# go and add the domain to nginx #

```
cd /etc/nginx/sites-available
cat ampelos-default
```

```
# HTTP Webapp
server {
    listen 80;
    listen [::]:80;

    root /usr/share/nginx/html; # root is irrelevant
    index index.html index.htm; # this is also irrelevant

    server_name webapp.tld; # the domain on which we want to host the application. Since we set "default_server" previously, nginx will answer all hosts anyway.

    # redirect non-SSL to SSL
    location / {
        rewrite     ^ https://$server_name$request_uri? permanent;
    }
}

# HTTPS Webapp
server {
    listen 443 ssl http2; # ngx_http_spdy_module was superseded by ngx_http_v2_module
    server_name webapp.tld; # this domain must match Common Name (CN) in the SSL certificate

    root html; # irrelevant
    index index.html; # irrelevant

    ssl_certificate /etc/nginx/ssl/webapp.crt; # full path to SSL certificate and CA certificate concatenated together
    ssl_certificate_key /etc/nginx/ssl/webapp.key; # full path to SSL key
    ssl_dhparam /etc/nginx/ssl/dhparam.pem;

    # performance enhancement for SSL
    ssl_stapling on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 5m;

    # safety enhancement to SSL: make sure we actually use a safe cipher
    ssl_prefer_server_ciphers on;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:ECDHE-RSA-RC4-SHA:ECDHE-ECDSA-RC4-SHA:RC4-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK:!RC4';

    # config to enable HSTS(HTTP Strict Transport Security) https://developer.mozilla.org/en-US/docs/Security/HTTP_Strict_Transport_Security
    # to avoid ssl stripping https://en.wikipedia.org/wiki/SSL_stripping#SSL_stripping
    add_header Strict-Transport-Security "max-age=31536000;";

    # If your application is not compatible with IE <= 10, this will redirect visitors to a page advising a browser update
    # This works because IE 11 does not present itself as MSIE anymore
    if ($http_user_agent ~ "MSIE" ) {
        return 303 https://browser-update.org/update.html;
    }
    # if user inputs www subdomain url will redirect to regular domain.
    if ( $http_host ~* "www\.(.*)") {
                 rewrite ^ https://$1$request_uri permanent;
    }  
    # pass all webapp.tld requests to the webapp
    location / {
        proxy_pass http://127.0.0.1:port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade; # allow websockets
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Forwarded-For $remote_addr; # preserve client IP
	proxy_set_header X-Forwarded-Proto $scheme;
        # this setting allows the browser to cache the application in a way compatible with Meteor
        # on every applicaiton update the name of CSS and JS file is different, so they can be cache infinitely (here: 30 days)
        # the root path (/) MUST NOT be cached
        if ($uri != '/') {
            expires 30d;
        }
    }
}

```
Link the site on nginx.
```
ln -s /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/webapp
```

# SSL and chill #

Generate a strong key for the certificate.
```
openssl genrsa -out webapp.key 4096
```

Take that key and use it to create a Certificate Signing Request (CSR).
```
openssl req -out webapp.csr -key webapp.key -new -sha256
```

Submit the CSR to a third party signer. Copy the resulting CRT and Intermediate CRT. Create them and cat them.

```
vi webapp.crt
(...)
vi intermediate.crt
(...)
cat webapp_crt.crt intermediate.crt > webapp.crt
```


### Generate a strong dhparam certificate

```
openssl dhparam -out dhparam.pem 4096
```

### Generate a CSR and Private Key ###

```
openssl req -newkey rsa:2048 -nodes -keyout example.com.key -out example.com.csr
```

The issuing authority may have signed the server certificate using an intermediate certificate that is not present in the certificate base of well-known trusted certificate authorities which is distributed with a particular browser. In this case the authority provides a bundle of chained certificates which should be concatenated to the signed server certificate. The server certificate must appear before the chained certificates in the combined file

before the authority comes back with the crt sign it yourself:

```
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
```
### build the NGINX image and see if it compiles

docker build -t nginx-proxy .

### start NGINX and see if everything works as expected

```
docker run -p 80:80 -p 443:443 -d nginx-alpine
```

#### Need to add in here where volumes are going to be storing repositories.

```
docker volume create --name gogs-data
```

```
docker run -p 3000:3000 -d kioshi-gogs -v gogs-data:/data gogs/gogs
```

```
docker pull mysql
```

```
docker run --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=password -d mysql
```

#### all of our applications initial databases should be built into a dockerfile repo for mysql

```
docker exec -it some-mysql bash
```

```
root@fskdfjskdfj:/# mysql -u root -p
password: password
mysql > CREATE DATABASE gogs;
```

#### Test your cluster

```
etcdctl member list
```

```
etcdctl cluster-health
```
