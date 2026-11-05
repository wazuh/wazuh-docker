## variables
APT_KEY=https://packages-dev.wazuh.com/key/GPG-KEY-WAZUH
GPG_SIGN="gpgcheck=1\ngpgkey=${APT_KEY}]"
REPOSITORY="[wazuh]\n${GPG_SIGN}\nenabled=1\nname=EL-\$releasever - Wazuh\nbaseurl=https://packages-dev.wazuh.com/pre-release/yum/\nprotect=1"

## WAZUH_PACKAGES_SOURCE is set by build-images.sh: 'production' (--release), 'pre-release' (-d)
## or empty, in which case the v<version> tag of wazuh/wazuh decides
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
  APT_KEY=https://packages.wazuh.com/key/GPG-KEY-WAZUH
  GPG_SIGN="gpgcheck=1\ngpgkey=${APT_KEY}]"
  REPOSITORY="[wazuh]\n${GPG_SIGN}\nenabled=1\nname=EL-\$releasever - Wazuh\nbaseurl=https://packages.wazuh.com/4.x/yum/\nprotect=1"
fi

rpm --import "${APT_KEY}"
echo -e "${REPOSITORY}" | tee /etc/yum.repos.d/wazuh.repo
