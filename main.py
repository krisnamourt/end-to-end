import flask
from flask import jsonify, Response, request
from flask_httpauth import HTTPBasicAuth
import jsonpickle

from src.service import list_instaces_from_elb,attach_instace_to_elb,deattach_instace_from_elb

app = flask.Flask(__name__)
app.config["DEBUG"] = True

auth = HTTPBasicAuth()

user = 'jane.doe@email.com'
pw = '1234xyz'


@auth.verify_password
def verify_password(username, password):    
    if username==user and password==pw:
        return True
    else: 
        return False

@app.route('/healthcheck', methods=['GET'])
def home2():
    print ("Health")
    return  Response("everything is OK",status=200)

@app.route('/elb/<elb>', methods=['GET'])
@auth.login_required
def list_instances(elb):
    result = list_instaces_from_elb(elb)
    return  Response(jsonpickle.encode(result['object'], unpicklable=False),status=result['status'], mimetype='application/json')
    

@app.route('/elb/<elb>', methods=['POST'])
@auth.login_required
def attach_instance(elb):    
    result =  attach_instace_to_elb(elb,request.json['instanceId'])
    return  Response(jsonpickle.encode(result['object'], unpicklable=False),status=result['status'], mimetype='application/json')


@app.route('/elb/<elb>', methods=['DELETE'])
@auth.login_required
def remove_instance(elb):
    result =  deattach_instace_from_elb(elb,request.json['instanceId'])
    return  Response(jsonpickle.encode(result['object'], unpicklable=False),status=result['status'], mimetype='application/json')
