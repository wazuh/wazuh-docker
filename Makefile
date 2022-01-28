WAZUH_VERSION ?= 4.4.0-1
WAZUH_KIBANA_VERSION ?= 4.4.0

DEV_STACK = docker-compose.yml 
PROD_STACK = production-cluster.yml
BUILD_STACK = build-from-sources.yml
CERT_STACK = generate-opendistro-certs.yml
PROD_DIR = production_cluster
SSL_DIR = $(PROD_DIR)/ssl_certs
NGINX_SSL = $(PROD_DIR)/nginx/ssl
KIBANA_SSL = $(PROD_DIR)/kibana_ssl/

DEFAULT_FLAGS = -d --remove-orphans
COMPOSE = docker-compose


images-build:
	WAZUH_VERSION=$(WAZUH_VERSION) WAZUH_KIBANA_VERSION=$(WAZUH_KIBANA_VERSION) $(COMPOSE) -f $(BUILD_STACK) up


certs-create: prod-stop
	$(COMPOSE) -f $(CERT_STACK) run --rm generator 
	bash $(NGINX_SSL)/generate-self-signed-cert.sh
	bash $(KIBANA_SSL)/generate-self-signed-cert.sh

dev-up:
	WAZUH_VERSION=$(WAZUH_VERSION) WAZUH_KIBANA_VERSION=$(WAZUH_KIBANA_VERSION) $(COMPOSE) up $(DEFAULT_FLAGS) 

dev-down:
	WAZUH_VERSION=$(WAZUH_VERSION) WAZUH_KIBANA_VERSION=$(WAZUH_KIBANA_VERSION)	$(COMPOSE) down 

prod-elk-run: 
	WAZUH_VERSION=$(WAZUH_VERSION) WAZUH_KIBANA_VERSION=$(WAZUH_KIBANA_VERSION) $(COMPOSE) -f $(PROD_STACK) up elasticsearch elasticsearch-2 elasticsearch-3 $(DEFAULT_FLAGS)

prod-kibana-run: 
	WAZUH_VERSION=$(WAZUH_VERSION) WAZUH_KIBANA_VERSION=$(WAZUH_KIBANA_VERSION) $(COMPOSE) -f $(PROD_STACK) up kibana $(DEFAULT_FLAGS)

prod-nginx-run: 
	WAZUH_VERSION=$(WAZUH_VERSION) WAZUH_KIBANA_VERSION=$(WAZUH_KIBANA_VERSION) $(COMPOSE) -f $(PROD_STACK) up nginx $(DEFAULT_FLAGS)

prod-run:
	WAZUH_VERSION=$(WAZUH_VERSION) WAZUH_KIBANA_VERSION=$(WAZUH_KIBANA_VERSION) $(COMPOSE) -f $(PROD_STACK) up $(DEFAULT_FLAGS)

prod-up: 
	WAZUH_VERSION=$(WAZUH_VERSION) WAZUH_KIBANA_VERSION=$(WAZUH_KIBANA_VERSION) $(COMPOSE) -f $(PROD_STACK) up $(DEFAULT_FLAGS)

prod-stop:
	WAZUH_VERSION=$(WAZUH_VERSION) WAZUH_KIBANA_VERSION=$(WAZUH_KIBANA_VERSION) $(COMPOSE) -f $(PROD_STACK) stop

prod-down: 
	WAZUH_VERSION=$(WAZUH_VERSION) WAZUH_KIBANA_VERSION=$(WAZUH_KIBANA_VERSION) $(COMPOSE) -f $(PROD_STACK) down

certs-clean: prod-stop
	rm -f $(SSL_DIR)/admin* $(SSL_DIR)/node* $(SSL_DIR)/root* $(SSL_DIR)/filebeat* $(SSL_DIR)/intermediate* $(SSL_DIR)/client-cert*

clean:  certs-clean dev-down prod-down