#!/bin/sh

rm ecs-compose.yml
rm ecs-params.yml

cd .github/terraform && terraform init 

export $(cat .env | xargs)

aws ecs update-service --cluster $cluster --service elb-python-api --desired-count 0

sleep 7

aws ecs delete-service --cluster $cluster --service elb-python-api

terraform destroy --auto-approve  