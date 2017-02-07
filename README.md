# Docker Wazuh+ELK stack

.. note:: These Docker containers are based on "deviantony" dockerfiles, which can be found at `https://github.com/deviantony/docker-elk <https://github.com/deviantony/docker-elk>`_. We created our own fork, which we test and maintain. Thank you Anthony Lapenna for your contribution to the community.

Run the latest version of the ELK (Elasticseach, Logstash, Kibana) stack with Docker and Docker-compose.

It will give you the ability to analyze any data set by using the searching/aggregation capabilities of Elasticseach and the visualization power of Kibana.

Based on the official images:

* [Wazuh](https://github.com/wazuh/wazuh)
* [logstash](https://registry.hub.docker.com/_/logstash/)
* [elasticsearch](https://registry.hub.docker.com/_/elasticsearch/)
* [kibana](https://registry.hub.docker.com/_/kibana/)


# Requirements

## Setup

1. Install [Docker](http://docker.io).
2. Install [Docker-compose](http://docs.docker.com/compose/install/) **version >= 1.6**.
3. Clone this repository

## Increase max_map_count on your host (Linux)

You need to increase `max_map_count` on your Docker host:

```bash
$ sudo sysctl -w vm.max_map_count=262144
```
To set this value permanently, update the vm.max_map_count setting in /etc/sysctl.conf. To verify after rebooting, run sysctl vm.max_map_count.

## SELinux

On distributions which have SELinux enabled out-of-the-box you will need to either re-context the files or set SELinux into Permissive mode in order for docker-elk to start properly.
For example on Redhat and CentOS, the following will apply the proper context:

```bash
.-root@centos ~
-$ chcon -R system_u:object_r:admin_home_t:s0 docker-elk/
```

# Usage

Start the ELK stack using *docker-compose*:

```bash
$ docker-compose up
```

You can also choose to run it in background (detached mode):

```bash
$ docker-compose up -d
```

And then access Kibana UI by hitting [http://localhost:5601](http://localhost:5601) with a web browser.

By default, the stack exposes the following ports:
* 1514: Wazuh UDP.
* 1515: Wazuh TCP.
* 514 : Wazuh UDP.
* 55000: Wazuh API.
* 5000: Logstash TCP input.
* 9200: Elasticsearch HTTP
* 9300: Elasticsearch TCP transport
* 5601: Kibana

*WARNING*: If you're using *boot2docker*, you must access it via the *boot2docker* IP address instead of *localhost*.

*WARNING*: If you're using *Docker Toolbox*, you must access it via the *docker-machine* IP address instead of *localhost*.

# Configuration

*NOTE*: Configuration is not dynamically reloaded, you will need to restart the stack after any change in the configuration of a component.

## How can I tune Kibana configuration?

The Kibana default configuration is stored in `kibana/config/kibana.yml`.

## How can I tune Logstash configuration?

The logstash configuration is stored in `logstash/config/logstash.conf`.

The folder `logstash/config` is mapped onto the container `/etc/logstash/conf.d` so you
can create more than one file in that folder if you'd like to. However, you must be aware that config files will be read from the directory in alphabetical order.

## How can I specify the amount of memory used by Logstash?

The Logstash container use the *LS_HEAP_SIZE* environment variable to determine how much memory should be associated to the JVM heap memory (defaults to 500m).

If you want to override the default configuration, add the *LS_HEAP_SIZE* environment variable to the container in the `docker-compose.yml`:

```yml
logstash:
  image: wazun/wazuh-logstash:latest
  command: -f /etc/logstash/conf.d/
  volumes:
    - ./logstash/config:/etc/logstash/conf.d
  ports:
    - "5000:5000"
  networks:
    - docker_elk
  depends_on:
    - elasticsearch
  environment:
    - LS_HEAP_SIZE=2048m
```

## How can I tune Elasticsearch configuration?

The Elasticsearch container is using the shipped configuration and it is not exposed by default.

If you want to override the default configuration, create a file `elasticsearch/config/elasticsearch.yml` and add your configuration in it.

Then, you'll need to map your configuration file inside the container in the `docker-compose.yml`. Update the elasticsearch container declaration to:

```yml
elasticsearch:
  image: wazuh/wazuh-elasticsearch:latest
  ports:
    - "9200:9200"
    - "9300:9300"
  environment:
    ES_JAVA_OPTS: "-Xms1g -Xmx1g"
  networks:
    - docker_elk
```

## How can I configure Wazuhapp plugin?

Select Wazuh APP in the left menu and then add the parameters

![Alt text](images/image-1.png?raw=true "Image 1")

The default configuration is:

```
User: foo
Password: bar
URL: http://wazuh
Port: 55000
```

![Alt text](images/image-2.png?raw=true "Image 2")


# Storage

## How can I store Elasticsearch data?

The data stored in Elasticsearch will be persisted after container reboot but not after container removal.

In order to persist Elasticsearch data even after removing the Elasticsearch container, you'll have to mount a volume on your Docker host. Update the elasticsearch container declaration to:

```yml
elasticsearch:
  image: wazuh/wazuh-elasticsearch:latest
  command: elasticsearch -Des.network.host=_non_loopback_ -Des.cluster.name: my-cluster
  ports:
    - "9200:9200"
    - "9300:9300"
  environment:
    ES_JAVA_OPTS: "-Xms1g -Xmx1g"
  networks:
    - docker_elk
  volumes:
    - /path/to/storage:/usr/share/elasticsearch/data
```

This will store elasticsearch data inside `/path/to/storage`.

## Final docker-compose file

```yml
version: '2'

services:
  wazuh:
    image: wazuh/wazuh:latest
    hostname: wazuh-manager
    ports:
      - "1514:1514"
      - "1515:1515"
      - "514:514"
      - "55000:55000"
    networks:
      - docker_elk
  elasticsearch:
    image: elasticsearch:latest
    hostname: elasticsearch
    command: elasticsearch -E node.name="node-1" -E cluster.name="wazuh" -E network.host=0.0.0.0
    ports:
      - "9200:9200"
      - "9300:9300"
    environment:
      ES_JAVA_OPTS: "-Xms1g -Xmx1g"
    networks:
      - docker_elk
  logstash:
    image: wazuh/wazuh-logstash:latest
    hostname: logstash
    command: -f /etc/logstash/conf.d/
    ports:
      - "5000:5000"
#    volumes_from:
#      - wazuh
    networks:
      - docker_elk
    depends_on:
      - wazuh/wazuh-elasticsearch
    environment:
      - LS_HEAP_SIZE=2048m
  kibana:
    image: wazuh/wazuh-kibana:latest
    hostname: kibana
    ports:
      - "5601:5601"
    networks:
      - docker_elk
    depends_on:
      - wazuh/wazuh-elasticsearch
    entrypoint: sh wait-for-it.sh elasticsearch


networks:
  docker_elk:
    driver: bridge
```
