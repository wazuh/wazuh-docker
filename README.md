# IMPORTANT NOTE (not final release)

The first time than you runt this container can take a while until kibana finish the configuration, the Wazuh plugin can take a few minutes until finish the instalation, please be patient.

# Docker container Wazuh + ELK(5.3.0)

This Docker container source files can be found in our [Wazuh Github repository](https://github.com/wazuh/wazuh). It includes both an OSSEC manager and an Elasticsearch single-node cluster, with Logstash and Kibana. You can find more information on how these components work together in our documentation.


## Documentation

* [Full documentation](http://documentation.wazuh.com)
* [OSSEC integration with ELK Stack]()
* [Docker container documentation]()
* [Docker Hub]()

## Credits and thank you

These Docker containers are based on "deviantony" dockerfiles which can be found at [https://github.com/deviantony/docker-elk] (https://github.com/deviantony/docker-elk), and "xetus-oss" dockerfiles, which can be found at [https://github.com/xetus-oss/docker-ossec-server](https://github.com/xetus-oss/docker-ossec-server). We created our own fork, which we test and maintain. Thank you Anthony Lapenna for your contribution to the community.
## References

* [Wazuh website](http://wazuh.com)
* [OSSEC project website](http://ossec.github.io)

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

If you like to change the default API configuration, you need to modify the file ``user`` in the path ``/var/ossec/api/configuration/auth/user``, you can generate other password with any ``htpasswd`` generator.

![Alt text](images/image-2.png?raw=true "Image 2")


# Storage

## How can I store Wazuh data?

The data stored in Wazuh will be persisted after container reboot but not after container removal.

In order to persist Wazuh data even after removing the Wazuh container, you'll have to mount a volume on your Docker host. Update the Wazuh container declaration to:

```yml
elasticsearch:
  image: wazuh/wazuh:latest
  hostname: wazuh-manager
  ports:
    - "1514:1514"
    - "1515:1515"
    - "514:514"
    - "55000:55000"
  networks:
    - docker_elk
  volumes:
    - /path/to/storage:/var/ossec/data
```

This will store Wazuh data inside `/path/to/storage`.

## How can I store Elasticsearch data?

The data stored in Elasticsearch will be persisted after container reboot but not after container removal.

In order to persist Elasticsearch data even after removing the Elasticsearch container, you'll have to mount a volume on your Docker host. Update the elasticsearch container declaration to:

```yml
elasticsearch:
  image: elasticsearch:5.3.0
  hostname: elasticsearch
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

# Run the containers.

In order to run the containers, first clone this repository, and then run the follow commands

```
docker-compose build && docker-compose up -d
```

# Docker compose file

```
version: '2'

services:
  wazuh:
    image: wazuh/wazuh
    hostname: wazuh-manager
    restart: always
    ports:
      - "1514/udp:1514/udp"
      - "1515:1515"
      - "514/udp:514/udp"
      - "55000:55000"
    networks:
        - docker_elk
#    volumes:
#      - my-path:/var/ossec/data
    depends_on:
      - elasticsearch
  logstash:
    image: wazuh/wazuh-logstash
    hostname: logstash
    restart: always
    command: -f /etc/logstash/conf.d/
#    volumes:
#      - my-path:/etc/logstash/conf.d
    links:
     - kibana
     - elasticsearch
    ports:
      - "5000:5000"
    networks:
        - docker_elk
    depends_on:
      - elasticsearch
    environment:
      - LS_HEAP_SIZE=2048m
  elasticsearch:
    image: elasticsearch:5.3.0
    hostname: elasticsearch
    restart: always
    command: elasticsearch -E node.name="node-1" -E cluster.name="wazuh" -E network.host=0.0.0.0
    ports:
      - "9200:9200"
      - "9300:9300"
    environment:
      ES_JAVA_OPTS: "-Xms2g -Xmx2g"
#    volumes:
#      - my-path:/usr/share/elasticsearch/data
    networks:
        - docker_elk
  kibana:
    image: wazuh/wazuh-kibana
    hostname: kibana
    restart: always
    ports:
      - "5601:5601"
    networks:
        - docker_elk
    depends_on:
      - elasticsearch
    entrypoint: sh wait-for-it.sh elasticsearch

networks:
  docker_elk:
    driver: bridge
    ipam:
      config:
      - subnet: 172.25.0.0/24

```

# Change Log
All notable changes to this project will be documented in this file.

## [v2.0]

### Added

- Wazuh modules manager.
- Wazuh module for OpenSCAP.
- Ruleset for OpenSCAP alerts.
- Kibana dashboards for OpenSCAP.
- Option at agent_control to restart all agents.
- Dynamic fields to rules and decoders.
- Dynamic fields to JSON in alerts/archives.
- CDB list lookup with dynamic fields.
- FTS for dynamic fields.
- Logcollector option to set the frequency of file checking.
- GeoIP support in Alerts (by Scott R Shinn).
- Internal option to output GeoIP data on JSON alerts.
- Matching pattern negation (by Daniel Cid).
- Syscheck and Rootcheck events on SQLite databases.
- Data migration tool to SQLite databases.
- Jenkins QA.
- 64-bit Windows registry keys support.
- Complete FIM data output to JSON and alerts.
- Username, date and inode attributes to FIM events on Unix.
- Username attribute to FIM events on Windows.
- Report changes (FIM file diffs) to Windows agent.
- File diffs to JSON output.
- Elastic mapping updated for new FIM events.
- Title and file fields extracted at Rootcheck alerts.
- Rule description formatting with dynamic field referencing.
- Multithreaded design for Authd server for fast and reliable client dispatching, with key caching and write scheduling.
- Auth registration client for Windows (by Gael Muller).
- Auth password authentication for Windows client.
- New local decoder file by default.
- Show server certificate and key paths at Authd help.
- New option for Authd to verify agent's address.
- Added support for new format at predecoder (by Brad Lhotsky).
- Agentless passlist encoding to Base64.
- New Auditd-specific log format for Logcollector.
- Option for Authd to auto-choose TLS/SSL method.
- Compile option for Authd to make it compatible with legacy OSs.
- Added new templates layout to auto-compose configuration file.
- New wodle for SQLite database syncing (agent information and fim/pm data).
- Added XML settings options to exclude some rules or decoders files.
- Option for agent_control to broadcast AR on all agents.
- Extended FIM event information forwarded by csyslogd (by Sivakumar Nellurandi).
- Report Syscheck's new file events on real time.

### Changed

- Isolated logtest directory from analysisd.
- Remoted informs Analysisd about agent ID.
- Updated Kibana dashboards.
- Syscheck FIM attributes to dynamic fields.
- Force services to exit if PID file creation fails.
- Atomic writing of client.keys through temporary files.
- Disabled remote message ID verification by default.
- Show actual IP on debug message when agents get connected.
- Enforce rules IDs to max 6 digits.
- OSSEC users and group as system (UI-hidden) users (by Dennis Golden).
- Increases Authd connection pool size.
- Use general-purpose version-flexible SSL/TLS methods for Authd registration.
- Enforce minimum 3-digit agent ID format.
- Exclude BTRFS from Rootcheck searching for hidden files inside directories (by Stehpan Joerrens).
- Moved OSSEC and Wazuh decoders to one directory.
- Prevent manage_agents from doing invalid actions (such methods for manager at agent).
- Disabled capturing of security events 5145 and 5156 on Windows agent.
- Utilities to rename an agent or change the IP address (by Antonio Querubin).
- Added quiet option for Logtest (by Dan Parriot).
- Output decoder information onto JSON alerts.
- Enable mail notifications by default for server installation.
- Agent control option to restart all agents' Syscheck will also restart manager's Syscheck.
- Make ossec-control to check Authd PID.
- Enforce every rule to contain a description.
- JSON output won't contain field "agentip" if tis value is "any".
- Don't broadcast Active Response messages to disconnected agents.
- Don't print Syscheck logs if it's disabled.
- Set default Syscheck and Rootcheck frequency to 12 hours.
- Generate FIM new file alert by default.
- Added option for Integrator to set the maximum log length.
- JSON output nested objects modelling through dynamic fields.
- Disable TCP for unsupported OSs.
- Show previous log on JSON alert.
- Removed confirmation prompt when importing an agent key successfully.
- Made Syscheck not to ignore files that change more than 3 times by default.
- Enabled JSON output by default.
- Updated default syscheck configuration for Windows agents.
- Limited agent' maximum connection time for notification time.
- Improved client.keys changing detection method by remoted: use date and inode.
- Changed boot service name to Wazuh.
- Active response enabled on Windows agents by default.
- New folder structure for rules and decoders.
- More descriptive logs about syscheck real-time monitoring.
- Renamed XML tags related to rules and decoders inclusion.
- Set default maximum agents to 8000.
- Removed FTS numeric bitfield from JSON output.
- Fixed ID misasignation by manage_agents when the gratest ID exceeds 32512.
- Run Windows Registry Syscheck scan on first stage when scan_on_start enabled.
- Set all Syscheck delay stages to a multiple of internal_options.conf/syscheck.sleep value.
- Changed JSON timestamp format to ISO8601.
- Overwrite @timestamp field from Logstash with the alert timestamp.

### Fixed

- Logcollector bug that inhibited alerts about file reduction.
- Memory issue on string manipulation at JSON.
- Memory bug at JSON alerts.
- Fixed some CLang warnings.
- Issue on marching OSSEC user on installing.
- Memory leaks at configuration.
- Memory leaks at Analysisd.
- Bugs and memory errors at agent management.
- Mistake with incorrect name for PID file (by Tickhon Clearscale).
- Agent-auth name at messages (it appeared to be the server).
- Avoid Monitord to log errors when the JSON alerts file doesn't exists.
- Agents numberig issue (minimum 3 digits).
- Avoid no-JSON message at agent_control when client.keys empty.
- Memory leaks at manage_agents.
- Authd error messages about connection to queue passed to warning.
- Issue with Authd password checking.
- Avoid ossec-control to use Dash.
- Fixed false error about disconnected agent when trying to send it the shared files.
- Avoid Authd to close when it reaches the maximum concurrency.
- Fixed memory bug at event diff execution.
- Fixed resource leak at file operations.
- Hide help message by useadd and groupadd on OpenBSD.
- Fixed error that made Analysisd to crash if it received a missing FIM file entry.
- Fixed compile warnings at cJSON library.
- Fixed bug that made Active Response to disable all commands if one of them was disabled (by Jason Thomas).
- Fixed segmentation fault at logtest (by Dan Parriot).
- Fixed SQL injection vulnerability at Database.
- Fixed Active Response scripts for Slack and Twitter.
- Fixed potential segmentation fault at file queue operation.
- Fixed file permissions.
- Fixed failing test for Apache 2.2 logs (by Brad Lhotsky).
- Fixed memory error at net test.
- Limit agent waiting time for retrying to connect.
- Fixed compile warnings on i386 architecture.
- Fixed Monitord crash when sending daily report email.
- Fixed script to null route an IP address on Windows Server 2012+ (by Theresa Meiksner).
- Fixed memory leak at Logtest.
- Fixed manager with TCP support on FreeBSD (by Dave Stoddard).
- Fixed Integrator launching at local-mode installation.
- Fixed issue on previous alerts counter (rules with if_matched_sid option).
- Fixed compile and installing error on Solaris.
- Fixed segmentation fault on syscheck when no configuration is defined.
- Fixed bug that prevented manage_agents from removing syscheck/rootcheck database.
- Fixed bug that made agents connected on TCP to hang if they are rejected by the manager.
- Fixed segmentation fault on remoted due to race condition on managing keystore.
- Fixed data lossing at remoted when reloading keystore.
- Fixed compile issue on MacOS.
- Fixed version reading at ruleset updater.
- Fixed detection of BSD.
- Fixed memory leak (by Byron Golden).
- Fixed misinterpretation of octal permissions given by Agentless (by Stephan Leemburg).
- Fixed mistake incorrect openssl flag at Makefile (by Stephan Leemburg).
- Silence Slack integration transmission messages (by Dan Parriot).
- Fixed OpenSUSE Systemd misconfiguration (By Stephan Joerrens).
- Fixed case issue on JSON output for Rootcheck alerts.
- Fixed potential issue on duplicated agent ID detection.
- Fixed issue when creating agent backups.

### Removed

- Deleted link to LUA sources.
- Delete ZLib generated files on cleaning.
- Removed maximum lines limit from diff messages (that remain limited by length).
