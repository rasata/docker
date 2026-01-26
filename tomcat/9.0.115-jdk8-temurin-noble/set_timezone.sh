#!/bin/bash
set -e

echo "${SERVER_TIMEZONE}" > /etc/timezone
ln -sf /usr/share/zoneinfo/${SERVER_TIMEZONE} /etc/localtime
dpkg-reconfigure -f noninteractive tzdata
locale-gen en_US.UTF-8
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=en_US.UTF-8