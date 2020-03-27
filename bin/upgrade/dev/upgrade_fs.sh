#!/bin/bash

echo "Running filesystem modifications"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
CUR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#upgrade nodejs
if [ -f /etc/redhat-release ]; then
	curl -sL https://rpm.nodesource.com/setup_10.x | bash -
	yum clean all
	yum remove -y nodejs
	yum install -y nodejs
fi

if [ -f /etc/lsb-release ]; then
    sudo dpkg --configure -a
    wget -qO- https://deb.nodesource.com/setup_10.x | bash -
    apt-get -f -y install
    apt-get -y --force-yes install nodejs || (echo "Failed to install nodejs." ; exit)
fi

#enable command line
bash "$DIR/scripts/detect.init.sh"


#remove predefined locale file, it should fallback to default one
rm -rf "$DIR/../frontend/express/public/localization/min/locale_en.properties"

#remove previous dependencies, as they need to be rebuild for new nodejs version
rm -rf "$DIR/../node_modules"

#run upgrade scripts
bash "$CUR/scripts/remove_moved_files.sh"
bash "$CUR/../19.08/scripts/remove_chrome_cache.sh"

#upgrade plugins
(cd "$DIR/.." && sudo npm install --unsafe-perm)
GLIBC_VERSION=$(ldd --version | head -n 1 | rev | cut -d ' ' -f 1 | rev)
if [[ "$GLIBC_VERSION" != "2.25" ]]; then
    (cd "$DIR/.." && sudo npm install argon2 --build-from-source)
fi
countly plugin upgrade push
(cd "$DIR/../plugins/push/api/parts/apn" && npm install --unsafe-perm)
countly plugin upgrade attribution
countly plugin upgrade web
countly plugin enable active_users
countly plugin enable performance-monitorin

#install dependencies, process files and restart countly
countly upgrade
