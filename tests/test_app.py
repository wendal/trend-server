import pytest
import json
from app import app, db
from models import TrendData


@pytest.fixture
def client():
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
        yield client
        with app.app_context():
            db.drop_all()


class TestReportAPI:
    def test_report_data_success(self, client):
        resp = client.post('/api/report',
            data=json.dumps({'key': 'test_key', 'value': 100}),
            content_type='application/json')
        assert resp.status_code == 201
        data = json.loads(resp.data)
        assert data['status'] == 'ok'
        assert 'id' in data
    
    def test_report_data_missing_key(self, client):
        resp = client.post('/api/report',
            data=json.dumps({'value': 100}),
            content_type='application/json')
        assert resp.status_code == 400
    
    def test_report_data_missing_value(self, client):
        resp = client.post('/api/report',
            data=json.dumps({'key': 'test_key'}),
            content_type='application/json')
        assert resp.status_code == 400
    
    def test_report_data_invalid_value(self, client):
        resp = client.post('/api/report',
            data=json.dumps({'key': 'test_key', 'value': 'abc'}),
            content_type='application/json')
        assert resp.status_code == 400
    
    def test_report_data_no_body(self, client):
        resp = client.post('/api/report',
            content_type='application/json')
        assert resp.status_code == 400


class TestGetKeysAPI:
    def test_get_keys_empty(self, client):
        resp = client.get('/api/keys')
        assert resp.status_code == 200
        data = json.loads(resp.data)
        assert data == []
    
    def test_get_keys_with_data(self, client):
        client.post('/api/report',
            data=json.dumps({'key': 'key1', 'value': 10}),
            content_type='application/json')
        client.post('/api/report',
            data=json.dumps({'key': 'key2', 'value': 20}),
            content_type='application/json')
        client.post('/api/report',
            data=json.dumps({'key': 'key1', 'value': 30}),
            content_type='application/json')
        
        resp = client.get('/api/keys')
        data = json.loads(resp.data)
        assert len(data) == 2
        assert 'key1' in data
        assert 'key2' in data


class TestGetDataAPI:
    def test_get_data_no_key(self, client):
        resp = client.get('/api/data')
        assert resp.status_code == 200
        data = json.loads(resp.data)
        assert isinstance(data, list)
    
    def test_get_data_with_key(self, client):
        client.post('/api/report',
            data=json.dumps({'key': 'test', 'value': 10}),
            content_type='application/json')
        client.post('/api/report',
            data=json.dumps({'key': 'test', 'value': 20}),
            content_type='application/json')
        
        resp = client.get('/api/data?key=test')
        assert resp.status_code == 200
        data = json.loads(resp.data)
        assert len(data) == 2
        assert data[0]['y'] == 10
        assert data[1]['y'] == 20
    
    def test_get_data_with_limit(self, client):
        for i in range(10):
            client.post('/api/report',
                data=json.dumps({'key': 'test', 'value': i}),
                content_type='application/json')
        
        resp = client.get('/api/data?key=test&limit=5')
        data = json.loads(resp.data)
        assert len(data) == 5
    
    def test_get_data_wrong_key(self, client):
        client.post('/api/report',
            data=json.dumps({'key': 'test', 'value': 10}),
            content_type='application/json')
        
        resp = client.get('/api/data?key=nonexistent')
        data = json.loads(resp.data)
        assert data == []


class TestGetAllDataAPI:
    def test_get_all_data_with_key(self, client):
        client.post('/api/report',
            data=json.dumps({'key': 'test', 'value': 10}),
            content_type='application/json')
        
        resp = client.get('/api/data/all?key=test')
        assert resp.status_code == 200
        data = json.loads(resp.data)
        assert len(data) == 1
        assert data[0]['key'] == 'test'
        assert data[0]['value'] == 10
        assert 'timestamp' in data[0]


class TestIndexPage:
    def test_index_page(self, client):
        resp = client.get('/')
        assert resp.status_code == 200
        assert b'<html' in resp.data