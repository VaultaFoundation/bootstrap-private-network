from flask import Flask, jsonify, request
import logging
import re
import subprocess

logging.basicConfig(level=logging.INFO)

app = Flask(__name__, static_url_path='/service/static')

def run_script(command_list):
    try:
        result = subprocess.run(
            command_list,
            check=True,
            capture_output=True,
            text=True
        )
        return {"output": result.stdout.strip(), "error": result.stderr.strip()}, 200
    except subprocess.CalledProcessError as e:
        return {
            "output": e.stdout.strip(),
            "error": e.stderr.strip(),
            "returncode": e.returncode
        }, 500

def is_valid_username(username):
    return re.match(r'^[a-z1-5.]{1,12}$', username) is not None

@app.route('/service/health')
def health():
    return jsonify({"status": "ok"}), 200
    
@app.route('/service/hello')
def hello():
    logging.info(f"Executing hello")
    return "Hello from Flask under /service!"
    
@app.route('/service/create_keys', methods=['POST'])
def create_keys():
    logging.info(f"Executing create_keys")
    response, code = run_script(['cleos','create','key','--to-console'])
    return jsonify(response), code

@app.route('/service/nodeos_version')
def nodeos_version():
    logging.info(f"Executing nodeos version")
    response, code = run_script(['nodeos','--full-version'])
    return jsonify(response), code
        
@app.route('/service/cdt_version')
def cdt_version():
    logging.info(f"Executing cdt_version")
    response, code = run_script(['cdt-cpp','--version'])
    return jsonify(response), code

@app.route('/service/create_account', methods=['POST'])
def create_account():
    data = request.json
    user_name = data.get('userName')
    public_key = data.get('publicKey')

    if not user_name or not public_key:
        return jsonify({"error": "Missing userName or publicKey"}), 400

    logging.info(f"Executing create_account for user: {user_name} ")

    if not is_valid_username(user_name):
        return jsonify({"error": "Invalid userName"}), 400

    response, code = run_script(["./create_account.sh", user_name, public_key])
    return jsonify(response), code

@app.route('/service/faucet', methods=['POST'])
def faucet():
    data = request.json
    user_name = data.get('userName')

    if not user_name:
        return jsonify({"error": "Missing userName"}), 400

    logging.info(f"Executing faucet for user: {user_name} ")

    if not is_valid_username(user_name):
        return jsonify({"error": "Invalid userName"}), 400

    response, code = run_script(["./faucet.sh", user_name])
    return jsonify(response), code

@app.route('/service/powerup', methods=['POST'])
def powerup():
    data = request.json
    user_name = data.get('userName')

    if not user_name:
        return jsonify({"error": "Missing userName"}), 400

    logging.info(f"Executing powerup for user: {user_name} ")
    
    if not is_valid_username(user_name):
        return jsonify({"error": "Invalid userName"}), 400
    
    response, code = run_script(["./powerup.sh", user_name])
    return jsonify(response), code

@app.route('/service/get_balance', methods=['POST'])
def get_balance():
    data = request.json
    user_name = data.get('userName')

    if not user_name:
        return jsonify({"error": "Missing userName"}), 400

    logging.info(f"Executing get_balance for user: {user_name} ")

    if not is_valid_username(user_name):
        return jsonify({"error": "Invalid userName"}), 400
        
    response, code = run_script(["./get_balance.sh", user_name])
    return jsonify(response), code
        
@app.route('/service/get_account', methods=['POST'])
def get_account():
    data = request.json
    user_name = data.get('userName')

    if not user_name:
        return jsonify({"error": "Missing userName"}), 400

    logging.info(f"Executing get_account for user: {user_name} ")
    
    if not is_valid_username(user_name):
        return jsonify({"error": "Invalid userName"}), 400

    response, code = run_script(["cleos","--url","http://127.0.0.1:8888","get","account","-j", user_name])
    return jsonify(response), code

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
    