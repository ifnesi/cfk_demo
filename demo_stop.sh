#!/bin/bash
kubectl config set-context --current --namespace=confluent

kubectl delete -f confluent-mongodb-connector.yaml
kubectl delete -f mongodb_community.yaml
helm uninstall community-operator

kubectl delete -f confluent-datagen-connectors.yaml
kubectl delete -f confluent-platform.yaml
helm uninstall confluent-operator