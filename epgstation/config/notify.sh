#!/bin/sh
message=$1
curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$message $NAME\"}" __NOTIFY_WEBHOOK__

