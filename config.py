import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///trend.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    PORT = int(os.environ.get('PORT', 9800))
    HOST = os.environ.get('HOST', '0.0.0.0')