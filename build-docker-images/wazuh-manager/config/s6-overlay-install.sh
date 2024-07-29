#!/bin/bash

function getArchBasedS6Version() {
  case $(arch) in
    'aarch64' | 'arm64') echo "s6-overlay-aarch64.tar.gz"   ;;
    'x86_64'  | 'amd64') echo "s6-overlay-amd64.tar.gz"     ;;
    *)
      echo "Architecture $(arch) not supported" >> /dev/stderr;
      exit 1;
    ;;
  esac
}

S6_FILE=$(getArchBasedS6Version);
curl -fsLo "/tmp/${S6_FILE}" "https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/${S6_FILE}";
tar xzf "/tmp/${S6_FILE}" -C / --exclude="./bin";
tar xzf "/tmp/${S6_FILE}" -C /usr ./bin;
rm "/tmp/${S6_FILE}";
