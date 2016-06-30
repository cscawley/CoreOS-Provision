# Ampelos Moon Base Server Systems #

# How do I get set up? #
Get in the web server
```
ssh ampelos
```
Create a new docroot:
```
sudo -i
cd /home
mkdir webapp && cd webapp
```
## Create a new Meteor app ##

cd /etc/init
vi webapp.conf

```
# upstart service file at /etc/init/todos.conf
description "Meteor.js (NodeJS) application"
author "Daniel Speichert <daniel@speichert.pro>"

# When to start the service
start on started mongodb and runlevel [2345]

# When to stop the service
stop on shutdown

# Automatically restart process if crashed
respawn
respawn limit 10 5

# we don't use buil-in log because we use a script below
# console log

# drop root proviliges and switch to mymetorapp user
setuid todos
setgid todos

script
    export PATH=/opt/local/bin:/opt/local/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    export NODE_PATH=/usr/lib/nodejs:/usr/lib/node_modules:/usr/share/javascript
    # set to home directory of the user Meteor will be running as
    export PWD=/home/todos
    export HOME=/home/todos
    # leave as 127.0.0.1 for security
    export BIND_IP=127.0.0.1
    # the port nginx is proxying requests to
    export PORT=8080
    # this allows Meteor to figure out correct IP address of visitors
    export HTTP_FORWARDED_COUNT=1
    # MongoDB connection string using todos as database name
    export MONGO_URL=mongodb://localhost:27017/todos
    # The domain name as configured previously as server_name in nginx
    export ROOT_URL=https://todos.net
    # optional JSON config - the contents of file specified by passing "--settings" parameter to meteor command in development mode
    export METEOR_SETTINGS='{ "somesetting": "someval", "public": { "othersetting": "anothervalue" } }'
    # this is optional: http://docs.meteor.com/#email
    # commented out will default to no email being sent
    # you must register with MailGun to have a username and password there
    # export MAIL_URL=smtp://postmaster@mymetorapp.net:password123@smtp.mailgun.org
    # alternatively install "apt-get install default-mta" and uncomment:
    # export MAIL_URL=smtp://localhost
    exec node /home/todos/bundle/main.js >> /home/todos/todos.log
end script
```

# Create a new Ghost Blog #

Download Ghost unzip the contents:
```
wget https://ghost.org/zip/ghost-latest.zip
unzip -d . ghost-latest.zip
```
Install dependencies:
```
npm install --production
```
Configure:
```
cp config.example.js config.js
```

```
var path = require('path'),
    config;

config = {
    // ### Production
    // When running Ghost in the wild, use the production environment
    // Configure your URL and mail settings here
    production: {
        url: 'https://webapp.tld',
        mail: {
            // Your mail settings
        },
        database: {
            client: 'sqlite3',
            connection: {
                filename: path.join(__dirname, '/content/data/ghost.db')
            },
            debug: false
        },

        server: {
            // Host to be passed to node's `net.Server#listen()`
            host: ' Server IP Address',
            // Port to be passed to node's `net.Server#listen()`, for iisnode s$
            port: '2368'
        }
    },

(...)
```

# Create unix user and init upstart file #

Add new user and create a new password when prompted:
```
adduser --shell /bin/bash --gecos 'web application' webapp
```
Change the permissions of the docroot to the new user/group
```
chown -R website:website /home/webapp
```
go to the init scripts and create a new conf file:
```
cd /etc/init
vi website.conf
```
Copy Pasta... But change 'webapp' to the new web user/docroot obviously:
```
description "ghost blog (NodeJS) application"
author "Carrucan <carrucan@ampelos.io>"

# When to start the service
start on runlevel [2345]

# When to stop the service
stop on shutdown

# Automatically restart process if crashed
respawn
respawn limit 10 5

# we don't use buil-in log because we use a script below
# console log

# drop root proviliges and switch to website user
setuid webapp
setgid webapp

script
    cd /home/webapp
    npm start --production
end script
```

Start the new webapp and pack a bowl:
```
start webapp
```

# go and add the domain to nginx #

```
cd /etc/nginx/sites-available
cat ampelos-default
```

Copy these specially crafted server blocks and create a new host file. Change all given "webapp" references to the new domain and "tld" references to the new tld. Also replace "port" with the chosen application port.

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
    listen 443 ssl spdy; # we enable SPDY here
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
        proxy_set_header Connection $connection_upgrade;
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
### Generate a CSR and Private Key ###

```
openssl req -newkey rsa:2048 -nodes -keyout example.com.key -out example.com.csr
```

The issuing authority may have signed the server certificate using an intermediate certificate that is not present in the certificate base of well-known trusted certificate authorities which is distributed with a particular browser. In this case the authority provides a bundle of chained certificates which should be concatenated to the signed server certificate. The server certificate must appear before the chained certificates in the combined file

The resulting file should be used in the ssl_certificate directive

```
server {
    listen              443 ssl;
    server_name         www.example.com;
    ssl_certificate     www.example.com.chained.crt;
    ssl_certificate_key www.example.com.key;
    ...
}
```
before the authority comes back with the crt sign the damn thing yourself:

```
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
```

do like that so you can look at your site while your cert authority gets it's shit together.

Test the reverse proxy.
```
nginx -t
```

If that succeeds restart the reverse proxy and go smoke weed.
```
nginx -s reload
```

# Troubleshooting the production environment #

Run these init commands to check status and/or inspect these logs to get detail on any error which may have occurred.

crt info:

```
openssl x509 -noout -text -in webapp.crt -modulus
```
crt and key match troubleshooting:
```
openssl x509 -noout -modulus -in webapp.crt | openssl md5
(stdin)=weac2dd6a579a693b581c88d4201e62f
openssl rsa -noout -modulus -in webapp.key | openssl md5
(stdin)=weac2dd6a579a693b581c88d4201e62f
```

see if nginx is talking on the network
```
netstat -nlp | grep nginx
```

change node version

```
su -i
nvm install xx.xx.xx
nvm use xx.xx.xx
n=$(which node);n=${n%/bin/node}; chmod -R 755 $n/bin/*; sudo cp -r $n/{bin,lib,share} /usr/local
```

application troubleshooting:
```
status ampelos
cat /home/ampelos/ampelos.log
service nginx status
cat /var/log/nginx/error.log
status mongodb
cat /var/log/mongodb/mongodb.log
top
vmstat 1
sudo cat /var/log/rkhunter.log
```
VIM help
```
text selection

If you want to do the same thing to a collection of lines, like cut, copy, sort, or format, you first need to select the text. Get out of insert mode, hit one of the options below, and then move up or down a few lines. You should see the selected text highlighted.

V       - selects entire lines
v       - selects range of text
ctrl-v  - selects columns
gv      - reselect block
After selecting the text, try d to delete, or y to copy, or :s/match/replace/, or :center, or !sort, or...

Here's one way to move selected text over a few spaces:

 - select a chunk of code using capital V and the arrow keys (or j, k)
 - type colon
 - then type s/^/   /
 - hit return
```
