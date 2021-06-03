import boto3
import logging
from botocore.exceptions import ClientError
from flask import  Response
from src.machine_info import MachineInfo

client = boto3.client('elbv2')
ec2 = boto3.client('ec2')

def list_instaces_from_elb(elb):
    try:
        elbs = get_elbs_by_name(elb)

        targetGroup = get_target_groups_from_elbs(elbs)

        print(targetGroup['TargetGroups'][0]['TargetGroupArn'])

        response = get_targets_from_target_groups(targetGroup)

        print(response['TargetHealthDescriptions'])

        instances = []
        for targetHealth in response['TargetHealthDescriptions']:
            instance = get_instance_from_id([targetHealth['Target']['Id'],])
            
            instances.append(instance)   
        return { "status": 200,"object": instances }
    except ClientError as e:
        if e.response['Error']['Code'] == 'LoadBalancerNotFound':
            logging.error(e)
            return { "status": 404,"object": {"message":"missing ELB"} }
        else:
            logging.error(e)
            return { "status": 500,"object": {"message":"Internal error"} }


def attach_instace_to_elb(elb, instanceId):
    try:
        elbs = get_elbs_by_name(elb)

        targetGroup = get_target_groups_from_elbs(elbs)

        targets = get_targets_from_target_groups(targetGroup)

        for targetHealth in targets['TargetHealthDescriptions']:
            if instanceId==targetHealth['Target']['Id']:
                return { "status": 409,"object": {"message":"instance already on load balancer"} }

        instance = get_instance_from_id(instanceId)

        attach_instante_to_target(targetGroup,instanceId)        

        return { "status": 201,"object": instance }
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidTarget':
            logging.error(e)
            return { "status": 404,"object": {"message":"The specified target does not exist, is not in the same VPC as the target group, or has an unsupported instance type"} }
        elif e.response['Error']['Code'] == 'TooManyRegistrationsForTargetId':
            logging.error(e)
            return { "status": 404,"object": {"message":"You've reached the limit on the number of times a target can be registered with a load balancer."} }
        elif e.response['Error']['Code'] == 'TooManyTargets':
            logging.error(e)
            return { "status": 404,"object": {"message":"You've reached the limit on the number of targets."} }
        else:
            logging.error(e)
            return { "status": 500,"object": {"message":"Internal error"} }


def deattach_instace_from_elb(elb, instanceId):
    try:
        elbs = get_elbs_by_name(elb)

        targetGroup = get_target_groups_from_elbs(elbs)

        targets = get_targets_from_target_groups(targetGroup)

        instancePrenset = False
        for targetHealth in targets['TargetHealthDescriptions']:
            if instanceId==targetHealth['Target']['Id']:
                instancePrenset = True

        if instancePrenset==False:
            return { "status": 409,"object": {"message":"Instance not present in the elb"} }


        deattach_instante_to_target(targetGroup,instanceId)

        instance = get_instance_from_id(instanceId)

        return { "status": 201,"object": instance }
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidTarget':
            logging.error(e)
            return { "status": 404,"object": {"message":"The specified target does not exist, is not in the same VPC as the target group, or has an unsupported instance type."} }
        elif e.response['Error']['Code'] == 'TargetGroupNotFound':
            logging.error(e)
            return { "status": 404,"object": {"message":"The specified target group does not exist."} }
        else:
            logging.error(e)
            return { "status": 500,"object": {"message":"Internal error"} }



def get_elbs_by_name(name):
    elbs = client.describe_load_balancers(Names=[name,],)
    return elbs

def get_target_groups_from_elbs(elbs):
    targetGroup = client.describe_target_groups(
        LoadBalancerArn=elbs['LoadBalancers'][0]['LoadBalancerArn'],
    )
    return targetGroup

def get_targets_from_target_groups(target_groups):
    targets = client.describe_target_health(
        TargetGroupArn=target_groups['TargetGroups'][0]['TargetGroupArn']
    )
    return targets

def get_instance_from_id(instanceId):
    ids = []
    if type(instanceId) is str:
        ids.append(instanceId) 
    else: 
        for id in instanceId:
            if id.startswith('i-'):
                ids.append(id)

    
    instance = ec2.describe_instances(InstanceIds=ids,)
    print (instance)
    id = instance['Reservations'][0]['Instances'][0]['InstanceId']
    instanceType = instance['Reservations'][0]['Instances'][0]['InstanceType']
    launchTime = instance['Reservations'][0]['Instances'][0]['LaunchTime']   
    ip = instance['Reservations'][0]['Instances'][0]['PrivateIpAddress']   
            
    manchineInfo = MachineInfo(id,instanceType,launchTime)
    return manchineInfo,ip

def attach_instante_to_target(target_groups,instanceId):

    client.register_targets(
            TargetGroupArn=target_groups['TargetGroups'][0]['TargetGroupArn'],
            Targets=[
                {
                    'Id': instanceId,
                },
            ]
        )

def deattach_instante_to_target(target_groups,instanceId):
    client.deregister_targets(
            TargetGroupArn=target_groups['TargetGroups'][0]['TargetGroupArn'],
            Targets=[
                {
                    'Id': instanceId,
                },
            ]
        )