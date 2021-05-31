import flask
from flask import jsonify, Response, request
from flask_swagger import swagger
import jsonpickle

from src.service import list_instaces_from_elb,attach_instace_to_elb,deattach_instace_from_elb

app = flask.Flask(__name__)
app.config["DEBUG"] = True


@app.route('/healthcheck', methods=['GET'])
def home2():
    return  Response("everything is OK",status=200)

@app.route('/elb/<elb>', methods=['GET'])
def list_instances(elb):
    result = list_instaces_from_elb(elb)
    return  Response(jsonpickle.encode(result['object'], unpicklable=False),status=result['status'], mimetype='application/json')
    

@app.route('/elb/<elb>', methods=['POST'])
def attach_instance(elb):    
    result =  attach_instace_to_elb(elb,request.json['instanceId'])
    return  Response(jsonpickle.encode(result['object'], unpicklable=False),status=result['status'], mimetype='application/json')


@app.route('/elb/<elb>', methods=['DELETE'])
def remove_instance(elb):
    result =  deattach_instace_from_elb(elb,request.json['instanceId'])
    return  Response(jsonpickle.encode(result['object'], unpicklable=False),status=result['status'], mimetype='application/json')

@app.route("/spec")
def spec():
    swag = swagger(app)
    swag['info']['version'] = "1.0.0"
    swag['info']['title'] = "Site Reliability Engineer Test"
    swag['info']['description'] = "SRE Test - Loadsmart"
    return jsonify(swag)

#app.run()
