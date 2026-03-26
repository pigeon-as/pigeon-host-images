#!/bin/bash
export ENROLL_URL="${file.secrets.vars.enroll_url}"
export ENROLL_TOKEN="${exec.enroll_token}"
export ENROLL_CERT="${exec.enroll_cert}"
bash /usr/local/bin/setup-worker.sh
