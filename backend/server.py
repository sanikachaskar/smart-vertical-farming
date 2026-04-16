from flask import Flask, jsonify, render_template 
from flask_cors import CORS 
import sqlite3 
from datetime import datetime 
 
app = Flask(__name__, static_folder='../frontend', template_folder='../frontend') 
CORS(app) 
 
@app.route('/') 
def index(): return render_template('dashboard.html') 
 
@app.route('/api/status') 
def status(): 
    return jsonify({'temperature':23.5, 'humidity':65, 'soil':45, 'light':78, 'pump':False, 'led':True, 'fan':False}) 
 
if __name__ == '__main__': app.run(host='0.0.0.0', port=5000, debug=True) 
