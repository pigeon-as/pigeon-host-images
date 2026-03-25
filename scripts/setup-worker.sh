#!/bin/bash -ex
# Worker first-boot: LUKS setup + secret enrollment via ConfigDrive user_data.

if [ -z "$ENROLL_URL" ] || [ -z "$ENROLL_TOKEN" ]; then
  echo "ERROR: ENROLL_URL and ENROLL_TOKEN must be set"
  exit 1
fi

bash /usr/local/bin/configure-luks.sh

pigeon-enroll claim \
  -url "$ENROLL_URL" \
  -token "$ENROLL_TOKEN" \
  -scope worker \
  -output /encrypted/pigeon/secrets.json
