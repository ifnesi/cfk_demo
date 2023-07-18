![image](docs/confluent-logo-300-2.png)

# Confluent for Kubernetes Demo - Overview

This MacOS setup guide will help you to setup Confluent Platform (using Confluent for Kubernetes) and MongoDB Community edition (using MongoDB Operator).

![image](docs/architecture-diagram.png)

CfK demo based on https://github.com/confluentinc/confluent-kubernetes-examples/quickstart-deploy

MongoDB demo based on: https://github.com/mongodb/mongodb-kubernetes-operator/blob/master/config/samples/mongodb.com_v1_mongodbcommunity_additional_mongod_config_cr.yaml

# Pre-requisites
- `brew`
- `jq`
- `curl`
- [Docker Desktop](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos)

# Installation (only need to do that once)

Start Docker
Make sure to check the boxes `Enable Kubernetes` and `Show system containers (advanced)`:

<img src="docs/docker_settings.png" height="150"><br>

```
brew install jq

brew install curl

brew install kubectl

brew install helm

kubectl create namespace confluent

helm repo add confluentinc https://packages.confluent.io/helm

helm repo add mongodb https://mongodb.github.io/helm-charts
```

# Running the demo

To automatically setup the demo, run `demo_start.sh`, it should take less than 5 minutes to have everything up and running. Since Confluent for Kubernetes is stateful that command can be run multiple times (in case of failure).

Once completed, go to http://controlcenter.localhost:9021 to access Confluent Control Center.

To view the MongoDB documents, run the commands below:
```
kubectl -n confluent exec --stdin --tty mongo-0 -- /bin/bash

mongosh "mongodb+srv://demo-user:1234567890@mongo-svc.confluent.svc.cluster.local/admin?replicaSet=mongo&ssl=false"

use local;

db.getCollectionNames();

db.getCollection('accomplished_female_readers').find().forEach(printjson);

exit;

exit;
```

Output example:
```
{
  _id: ObjectId("64b69508567b804d86d7dff2"),
  USER_ID: 'User_3',
  PAGEID: 'Page_55',
  REGIONID: 'Region_1',
  GENDER: 'FEMALE'
}
{
  _id: ObjectId("64b69508567b804d86d7dff3"),
  USER_ID: 'User_5',
  PAGEID: 'Page_81',
  REGIONID: 'Region_1',
  GENDER: 'FEMALE'
}
{
  _id: ObjectId("64b69508567b804d86d7dff4"),
  USER_ID: 'User_8',
  PAGEID: 'Page_96',
  REGIONID: 'Region_7',
  GENDER: 'FEMALE'
}
```

## In case the start script fails, see below the steps to be followed:

### Confluent for Kubernetes
```
kubectl config set-context --current --namespace=confluent

helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes --namespace confluent

kubectl get pods
```

Wait for pod to be Running (output example):
```
NAME                                  READY   STATUS    RESTARTS   AGE
confluent-operator-...                1/1     Running   0          3s
```

### Confluent Platform
```
kubectl apply -f confluent-platform.yaml

kubectl get pods
```

Wait for pods to be Running (output example):
```
NAME                                  READY   STATUS    RESTARTS      AGE
confluent-operator-...                1/1     Running   0             2m6s
connect-0                             1/1     Running   0             2m
controlcenter-0                       1/1     Running   0             75s
kafka-0                               1/1     Running   0             2m
kafka-1                               1/1     Running   0             2m
kafka-2                               1/1     Running   0             2m
kafkarestproxy-0                      1/1     Running   0             75s
ksqldb-0                              1/1     Running   0             2m
schemaregistry-0                      1/1     Running   0             75s
schemaregistry-1                      1/1     Running   0             75s
zookeeper-0                           1/1     Running   0             2m
zookeeper-1                           1/1     Running   0             2m
zookeeper-2                           1/1     Running   0             2m
```


### Datagen connectors
```
kubectl apply -f confluent-datagen-connectors.yaml
```

### MongoDB
```
helm install community-operator mongodb/community-operator --namespace confluent

kubectl apply -f mongodb_community.yaml --namespace confluent

kubectl get pods
```

Wait for pods to be Running (output example):
```
NAME                                           READY   STATUS    RESTARTS        AGE
confluent-operator-...                         1/1     Running   0               3m34s
connect-0                                      1/1     Running   0               3m28s
controlcenter-0                                1/1     Running   0               2m43s
kafka-0                                        1/1     Running   0               3m28s
kafka-1                                        1/1     Running   0               3m28s
kafka-2                                        1/1     Running   0               3m28s
kafkarestproxy-0                               1/1     Running   0               2m43s
ksqldb-0                                       1/1     Running   0               3m28s
mongo-0                                        2/2     Running   0               68s
mongo-1                                        2/2     Running   0               46s
mongo-2                                        2/2     Running   0               26s
mongodb-kubernetes-operator-...                1/1     Running   0               79s
schemaregistry-0                               1/1     Running   0               2m43s
schemaregistry-1                               1/1     Running   0               2m43s
zookeeper-0                                    1/1     Running   0               3m28s
zookeeper-1                                    1/1     Running   0               3m28s
zookeeper-2                                    1/1     Running   0               3m28s
```

### ksqlDB
Go to http://controlcenter.localhost:9021, then run the following queries on your ksqlDB cluster:
```
CREATE STREAM IF NOT EXISTS PAGEVIEWS WITH (kafka_topic='pageviews', value_format='AVRO');

CREATE TABLE IF NOT EXISTS USERS (id STRING PRIMARY KEY) WITH (kafka_topic='users', value_format='AVRO');

CREATE STREAM IF NOT EXISTS PAGEVIEWS_FEMALE AS SELECT USERS.id as userid, CAST(USERS.id as STRING) AS user_id, pageid, regionid, gender FROM PAGEVIEWS LEFT JOIN USERS ON PAGEVIEWS.userid = USERS.id WHERE gender = 'FEMALE' EMIT CHANGES;

CREATE STREAM IF NOT EXISTS ACCOMPLISHED_FEMALE_READERS WITH (kafka_topic='accomplished_female_readers', value_format='AVRO') AS SELECT * FROM PAGEVIEWS_FEMALE WHERE CAST(SPLIT(PAGEID,'_')[2] as INT) >= 50 EMIT CHANGES;
```

#### Get MongoDB Credentials
```
kubectl get secret mongo-admin-demo-user -n confluent -o json | jq -r '.data | with_entries(.value |= @base64d)'
```

Output example:
```
{
  "connectionString.standard": "mongodb://demo-user:1234567890@mongo-0.mongo-svc.confluent.svc.cluster.local:27017,mongo-1.mongo-svc.confluent.svc.cluster.local:27017,mongo-2.mongo-svc.confluent.svc.cluster.local:27017/admin?replicaSet=mongo&ssl=false",
  "connectionString.standardSrv": "mongodb+srv://demo-user:1234567890@mongo-svc.confluent.svc.cluster.local/admin?replicaSet=mongo&ssl=false",
  "password": "1234567890",
  "username": "demo-user"
}
```

### MongoDB sink connector
```
kubectl apply -f confluent-mongodb-connector.yaml
```

Wait for connector to be Running. To view connector status, try:
```
curl connect-bootstrap-lb.localhost:8083/connectors

curl connect-bootstrap-lb.localhost:8083/connectors/mongodb-sink/status | jq

curl connect-bootstrap-lb.localhost:8083/connectors/mongodb-sink/status | jq -r '.tasks[0].trace'
```

# Stopping the demo

To automatically stop the demo, please run `demo_stop.sh`.

In case the stop script fails, see below the steps to be followed:
```
kubectl delete -f confluent-mongodb-connector.yaml

kubectl delete -f mongodb_community.yaml

helm uninstall community-operator

kubectl delete -f confluent-datagen-connectors.yaml

kubectl delete -f confluent-platform.yaml

helm uninstall confluent-operator
```
