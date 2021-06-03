#!/bin/sh

AWSREGION=us-east-1
ECR_HASH=$(date +%Y_%m_%d_%H_%M)


cd .github/terraform && terraform init && terraform apply --auto-approve  

export $(cat .env | xargs)

cd ../..

AWSACCOUNT=$(echo $ecr| cut -d'_' -f 1)

aws ecr get-login-password --region $AWSREGION | docker login --username AWS --password-stdin $AWSACCOUNT.dkr.ecr.eu-west-1.amazonaws.com

docker build -t $ecr:$ECR_HASH .
docker push $ecr:$ECR_HASH

sed "s|app_name|elb-python-api|g" .github/ecs/ecs-compose.yml > ecs-compose.yml
sed -i "s|image_app|$ecr:$ECR_HASH|" ecs-compose.yml
sed "s|tsk_role|$app_role|" .github/ecs/ecs-params.yml > ecs-params.yml
sed -i "s|exec_role|$ecs_role|" ecs-params.yml
sed -i "s|sg_task|$sg_task|" ecs-params.yml

ecs-cli compose --project-name elb-python-api -f ecs-compose.yml --ecs-params ecs-params.yml -c $cluster --region $AWSREGION service up --launch-type FARGATE --create-log-groups --target-group-arn $target_arn --container-name api --container-port 8000 --timeout 10