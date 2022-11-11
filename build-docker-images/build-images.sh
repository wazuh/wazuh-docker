WAZUH_IMAGE_VERSION=4.3.10
WAZUH_VERSION=$(echo $WAZUH_IMAGE_VERSION | sed -e 's/\.//g')
WAZUH_TAG_REVISION=1
WAZUH_CURRENT_VERSION=$(curl --silent https://api.github.com/repos/wazuh/wazuh/releases/latest | grep '\"tag_name\":' | sed -E 's/.*\"([^\"]+)\".*/\1/' | cut -c 2- | sed -e 's/\.//g')

## If wazuh manager exists in apt dev repository, change variables, if not, exit 1
if [ "$WAZUH_VERSION" -le "$WAZUH_CURRENT_VERSION" ]; then
  IMAGE_VERSION=${WAZUH_IMAGE_VERSION}
else
  IMAGE_VERSION=${WAZUH_IMAGE_VERSION}
fi

echo WAZUH_VERSION=$WAZUH_IMAGE_VERSION > .env
echo WAZUH_IMAGE_VERSION=$IMAGE_VERSION >> .env
echo WAZUH_TAG_REVISION=$WAZUH_TAG_REVISION >> .env

docker-compose -f build-docker-images/build-images.yml --env-file .env build --no-cache