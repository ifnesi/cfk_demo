#!/bin/bash

# Global variables
KSQLDB_ENDPOINT="http://ksqldb.localhost:8088"

while read ksqlCmd; do
	response=$(curl -w "\n%{http_code}" -X POST $KSQLDB_ENDPOINT/ksql \
	       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
	       --silent \
	       -d @<(cat <<EOF
	{
	  "ksql": "$ksqlCmd",
	  "streamsProperties": {
			"ksql.streams.auto.offset.reset":"earliest",
			"ksql.streams.cache.max.bytes.buffering":"0"
		}
	}
EOF
	))
	echo "$response" | {
	  read body
	  read code
	  echo ""
	  echo "$body" | jq -r ".[]"
	  echo "Status: $code"
	}
sleep 3;
done < $1
