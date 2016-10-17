Gogs Server recipe

# local SQL
*local SQL for development*

install mysql server
```
sudo apt-get -y install mysql-server
```

create a gogs sql script
```
vi gogs.sql
```

enter the following sql commands
```
DROP DATABASE IF EXISTS gogs;
CREATE DATABASE IF NOT EXISTS gogs CHARACTER SET utf8 COLLATE utf8_general_ci;
```

enter sql terminal
```
mysql -u root -p
password: your_password 
```

execute gogs sql script from sql terminal
```
< gogs.sql
```

## GO language

add git user
```
sudo adduser --disabled-login --gecos 'Gogs' git
```

become git user
```
sudo su - git
```

install go environment
```
mkdir local
```

get latest [GO](https://golang.org/dl/)
```
wget https://storage.googleapis.com/golang/gox.x.x.linux-amd64.tar.gz
```

de-tar the tarball
```
tar -C /home/git/local -xzf go$VERSION.$OS-$ARCH.tar.gz
```

Set GO paths
```
echo 'export GOROOT=$HOME/local/go' >> $HOME/.bashrc
echo 'export GOPATH=$HOME/go' >> $HOME/.bashrc
echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' >> $HOME/.bashrc
source $HOME/.bashrc
```

test Go
```
go
```

use Go to download Gogs
```
go get -d github.com/gogits/gogs
cd $GOPATH/src/github.com/gogits/gogs
go build
```

## Set up supervisor

download
```
sudo apt-get -y install supervisor
```

centralize log files
```
sudo mkdir -p /var/log/gogs
```

Create gogs configuration in supervisor conf file
```
sudo vi /etc/supervisor/supervisord.conf
```

add this configuration to the end of the file
```
[program:gogs]
directory=/home/git/go/src/github.com/gogits/gogs/
command=/home/git/go/src/github.com/gogits/gogs/gogs web
autostart=true
autorestart=true
startsecs=10
stdout_logfile=/var/log/gogs/stdout.log
stdout_logfile_maxbytes=1MB
stdout_logfile_backups=10
stdout_capture_maxbytes=1MB
stderr_logfile=/var/log/gogs/stderr.log
stderr_logfile_maxbytes=1MB
stderr_logfile_backups=10
stderr_capture_maxbytes=1MB
environment = HOME="/home/git", USER="git"
user = git
```

restart supervisor with the newly added Gogs config 
```
sudo service supervisor restart
```

see if there's a gogs process running
```
ps -ef | grep gogs
```

confirm this dialog and give everyone a high five.
```
root      1344  1343  0 08:55 ?        00:00:00 /home/git/go/src/github.com/gogits/gogs/gogs web
```

confirm that the log centralization is getting messages from the service
```
tail /var/log/gogs/stdout.log
```

confirm
```
2016/10/16 04:50:29 [I] Gogs: Go Git Service x.x.x.x
```

# app proxy

```
sudo apt-get -y install nginx
```

add an nginx server block for our gogs service
```
sudo vi /etc/nginx/sites-available/gogs
```

add in our patented ssl recipe
```
# HTTP Webapp
server {
    listen 80;
    listen [::]:80;

    root /usr/share/nginx/html; # root is irrelevant
    index index.html index.htm; # this is also irrelevant

    server_name ig88.screenplayhub.com; # the domain on which we want to host the application. Since we set "default_server" previously, nginx will answer all hosts anyway.

    # redirect non-SSL to SSL
    location / {
        rewrite     ^ https://$server_name$request_uri? permanent;
    }
}

# HTTPS Webapp
server {
    listen 443 ssl http2; # we enable SPDY here
    server_name ig88.screenplayhub.com; # this domain must match Common Name (CN) in the SSL certificate

    root html; # irrelevant
    index index.html; # irrelevant

    ssl_certificate /etc/nginx/ssl/ig88.screenplayhub.com.crt; # full path to SSL certificate and CA certificate concatenated together
    ssl_certificate_key /etc/nginx/ssl/ig88.screenplayhub.com.key; # full path to SSL key
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
        proxy_pass http://127.0.0.1:3000;
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

generate a strong dhparam promised by the server block
```
sudo openssl dhparam -out /etc/nginx/ssl/dhparam.pem 4096
```

add site to enabled server blocks
```
sudo ln -s /etc/nginx/sites-available/gogs /etc/nginx/sites-enabled/gogs
```

restart nginx
```
sudo service nginx restart
```

## update gogs

become git user
```
sudo su - git
```

as the git user pull the update and recompile gogs
```
cd $GOPATH/src/github.com/gogits/gogs
git pull origin master
go build
exit
```

restart the supervisor
```
sudo service supervisor restart
```

## logs

systemctl status nginx.service

tail -f /var/log/gogs/stdout.log