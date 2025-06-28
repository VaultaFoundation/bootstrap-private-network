from flask import Flask, jsonify, request
import subprocess

app = Flask(__name__, static_url_path='/service/static')

@app.route('/service/hello')
def hello():
    return "Hello from Flask under /service!"
    
@app.route('/service/create_keys', methods=['POST'])
def create_keys():
    try:
        result = subprocess.run(
            ['/home/enfuser/scripts/create_keys.sh'],
            capture_output=True, text=True, check=True
        )
        return jsonify({'output': result.stdout})
    except subprocess.CalledProcessError as e:
        return jsonify({'error': e.stderr}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
    