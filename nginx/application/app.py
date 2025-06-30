from flask import Flask, jsonify, request
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from werkzeug.middleware.proxy_fix import ProxyFix
import logging
import re
import subprocess

logging.basicConfig(level=logging.INFO)

# Create Memcached client
memcached_client = base.Client(('localhost', 11211))

app = Flask(__name__, static_url_path='/service/static')

# use x-forward proxy headers to get client details 
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1)

######
# Setup Rate Limits by Username
######
limiter = Limiter(
    get_remote_address,  # Default IP-based
    storage_uri="memcached://localhost:11211",
    app=app,
    default_limits=["100 per hour"]
)
def user_name_key():
    try:
        return request.json.get('userName') or get_remote_address()
    except:
        return get_remote_address()  # fallback if body isn't JSON

########
# Common func to run shell scripts
########
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

# validation function 
def is_valid_username(username):
    return re.match(r'^[a-z1-5.]{1,12}$', username) is not None

# Service calls 
@app.route('/service/health')
def health():
    return jsonify({"status": "ok"}), 200
    
@app.route('/service/hello')
def hello():
    logging.info(f"Executing hello")
    return jsonify({"message":"hello from service", "ip": get_remote_address()})
    
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
@limiter.limit("2 per day", key_func=user_name_key, error_message="Faucet limit exceeded. Max 2 requests per day per user.")
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
@limiter.limit("1 per 16 hours", key_func=user_name_key, error_message="Faucet limit exceeded. Max 1 request every 16 hours per user.")
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
    