## variables
REPOSITORY="packages-dev.wazuh.com/pre-release"

## WAZUH_PACKAGES_SOURCE is set by build-images.sh, as in check_repository.sh
case "${WAZUH_PACKAGES_SOURCE}" in
  production)
    WAZUH_TAG="v${WAZUH_VERSION}"
    ;;
  pre-release)
    WAZUH_TAG=""
    ;;
  *)
    HTTP_STATUS=$(curl --silent --output /dev/null --write-out "%{http_code}" "https://api.github.com/repos/wazuh/wazuh/git/ref/tags/v${WAZUH_VERSION}")
    case "${HTTP_STATUS}" in
      200) WAZUH_TAG="v${WAZUH_VERSION}" ;;
      404) WAZUH_TAG="" ;;
      *)
        echo "Error: could not check the v${WAZUH_VERSION} tag of wazuh/wazuh (HTTP status: ${HTTP_STATUS})." >&2
        exit 1
        ;;
    esac
    ;;
esac

## check tag to use the correct repository
if [[ -n "${WAZUH_TAG}" ]]; then
  REPOSITORY="packages.wazuh.com/4.x"
fi

yum install filebeat-${FILEBEAT_VERSION}-${FILEBEAT_REVISION} -y && \
curl -s https://${REPOSITORY}/filebeat/${WAZUH_FILEBEAT_MODULE} | tar -xvz -C /usr/share/filebeat/module