from flask import jsonify

def hello_world(request):
    if request.method != 'GET':
        return jsonify({"error": "Method not allowed"}), 405

    return jsonify({"message": "Hello, World!"}), 200
