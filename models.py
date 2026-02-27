from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

class TrendData(db.Model):
    __tablename__ = 'trend_data'
    
    id = db.Column(db.Integer, primary_key=True)
    key = db.Column(db.String(256), nullable=False, index=True)
    value = db.Column(db.Float, nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow, nullable=False, index=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'key': self.key,
            'value': self.value,
            'timestamp': self.timestamp.isoformat()
        }
    
    def to_chart_data(self):
        return {
            'x': self.timestamp.strftime('%Y-%m-%d %H:%M:%S'),
            'y': self.value
        }