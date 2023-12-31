CREATE STREAM IF NOT EXISTS PAGEVIEWS WITH (kafka_topic='pageviews', value_format='AVRO');
CREATE TABLE IF NOT EXISTS USERS (id STRING PRIMARY KEY) WITH (kafka_topic='users', value_format='AVRO');
CREATE STREAM IF NOT EXISTS PAGEVIEWS_FEMALE AS SELECT USERS.id as userid, CAST(USERS.id as STRING) AS user_id, pageid, regionid, gender FROM PAGEVIEWS LEFT JOIN USERS ON PAGEVIEWS.userid = USERS.id WHERE gender = 'FEMALE' EMIT CHANGES;
CREATE STREAM IF NOT EXISTS ACCOMPLISHED_FEMALE_READERS WITH (kafka_topic='accomplished_female_readers', value_format='AVRO') AS SELECT * FROM PAGEVIEWS_FEMALE WHERE CAST(SPLIT(PAGEID,'_')[2] as INT) >= 50 EMIT CHANGES;
