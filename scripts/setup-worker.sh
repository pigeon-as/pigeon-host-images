#!/bin/bash
set -eu
# Worker first-boot: LUKS setup + secret enrollment via ConfigDrive user_data.

: "${ENROLL_URL:?missing ENROLL_URL}"
: "${ENROLL_TOKEN:?missing ENROLL_TOKEN}"

bash /usr/local/bin/configure-luks.sh

pigeon-enroll claim \
  -url "$ENROLL_URL" \
  -token "$ENROLL_TOKEN" \
  -scope worker \
  -output /encrypted/pigeon/secrets.json

systemctl start pigeon-template.service
