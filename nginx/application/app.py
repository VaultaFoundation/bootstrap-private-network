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
            ['cleos','create','key','--to-console'],
            capture_output=True, text=True, check=True
        )
        return jsonify({'output': result.stdout})
    except subprocess.CalledProcessError as e:
        return jsonify({'error': e.stderr}), 500
        
@app.route('/service/nodeos_version')
def nodeos_version():
    try:
        result = subprocess.run(
            ['nodeos','--full-version'],
            capture_output=True, text=True, check=True
        )
        return jsonify({'output': result.stdout})
    except subprocess.CalledProcessError as e:
        return jsonify({'error': e.stderr}), 500
        
@app.route('/service/cdt_version')
def cdt_version():
    try:
        result = subprocess.run(
            ['cdt-cpp','--version'],
            capture_output=True, text=True, check=True
        )
        return jsonify({'output': result.stdout})
    except subprocess.CalledProcessError as e:
        return jsonify({'error': e.stderr}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
    