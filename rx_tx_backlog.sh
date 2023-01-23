#!/bin/bash

samples=${1:-1000}
sleep=${2:-.2}

port=${3:-26257}

f=/tmp/rx_tx.samples

rm -f $f

for i in $(seq 1 $samples); do
  sudo netstat -antlp \
      | grep $port \
      | grep -vF '127.0.0.1' \
      | awk '{print $2" "$3}' \
      | jq -R '.' \
      | jq -s '.
               | map(split(" ")
               | map(tonumber)
               | a2o(["rx", "tx"]))
               | add_all(["rx", "tx"])' >> $f
  sleep $sleep
done

cat $f | jq \
  --argjson qtl '50' \
  -s \
  '{rx: (map(.rx) | qtile($qtl)), tx: (map(.tx) | qtile($qtl))}'
