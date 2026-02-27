from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
from datetime import datetime
from config import Config
from models import db, TrendData

app = Flask(__name__)
app.config.from_object(Config)
CORS(app)
db.init_app(app)


@app.route('/')
def index():
    return render_template('index.html')


@app.route('/api/report', methods=['POST'])
def report_data():
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No data provided'}), 400
    
    key = data.get('key')
    value = data.get('value')
    
    if not key or value is None:
        return jsonify({'error': 'key and value are required'}), 400
    
    try:
        value = float(value)
    except (ValueError, TypeError):
        return jsonify({'error': 'value must be a number'}), 400
    
    trend = TrendData(key=key, value=value)
    db.session.add(trend)
    db.session.commit()
    
    return jsonify({'status': 'ok', 'id': trend.id}), 201


@app.route('/api/keys', methods=['GET'])
def get_keys():
    keys = db.session.query(TrendData.key).distinct().all()
    return jsonify([k[0] for k in keys])


@app.route('/api/data', methods=['GET'])
def get_data():
    key = request.args.get('key')
    limit = request.args.get('limit', 100, type=int)
    
    query = TrendData.query
    if key:
        query = query.filter(TrendData.key == key)
    
    data = query.order_by(TrendData.timestamp.desc()).limit(limit).all()
    data = list(reversed(data))
    
    return jsonify([d.to_chart_data() for d in data])


@app.route('/api/data/all', methods=['GET'])
def get_all_data():
    key = request.args.get('key')
    
    query = TrendData.query
    if key:
        query = query.filter(TrendData.key == key)
    
    data = query.order_by(TrendData.timestamp.asc()).all()
    
    return jsonify([d.to_dict() for d in data])


if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host=Config.HOST, port=Config.PORT, debug=True)