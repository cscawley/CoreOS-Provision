### initialize docker discovery to the private network.

on all three vms:

```
sudo mkdir /etc/systemd/system/docker.service.d/
```

create a custom.conf and insert the following:

```
[Service]
Environment="DOCKER_OPTS=-H=0.0.0.0:2376 -H unix:///var/run/docker.sock --cluster-advertise eth0:2376 --cluster-store etcd://127.0.0.1:2379"
```

reload the daemon

```
sudo systemctl daemon-reload
sudo systemctl restart docker
```

test if one of your docker services is discoverable from another:

```
docker -H tcp://10.1.0.51:2376 info
```

### Set up a swarm agent and manager in each node

###### ampelos-01

```
docker run -d --name swarm-agent \
    --net=host swarm:latest \
      join --addr=10.1.0.51:2376 \
      etcd://127.0.0.1:2379
```

```
docker run -d --name swarm-manager \
    --net=host swarm:latest manage \
      etcd://127.0.0.1:2379
```

###### ampelos-02

```
docker run -d --name swarm-agent \
    --net=host swarm:latest \
      join --addr=10.1.0.52:2376 \
      etcd://127.0.0.1:2379
```

```
docker run -d --name swarm-manager \
    --net=host swarm:latest manage \
      etcd://127.0.0.1:2379
```

###### ampelos-03

```
docker run -d --name swarm-agent \
    --net=host swarm:latest \
      join --addr=10.1.0.53:2376 \
      etcd://127.0.0.1:2379
```

```
docker run -d --name swarm-manager \
    --net=host swarm:latest manage \
      etcd://127.0.0.1:2379
```

### Create an overlay network

###### ampelos-01

```
docker -H tcp://10.1.0.51:2375 network create --driver overlay docker-net
```

and check out the new internal docker network.

docker -H tcp://10.1.0.53:2375 network ls
