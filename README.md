# 趋势展示服务器

HTTP数据上报与可视化展示服务

## 功能特性
- HTTP API数据上报 (key/value)
- SQLite数据库存储(含时间戳)
- Key管理(支持选择/输入)
- Chart.js折线图展示

## 快速开始

### 安装依赖
```bash
pip install -r requirements.txt
```

### 启动服务
```bash
python app.py
```

访问 http://localhost:9800

## API接口

### 数据上报
```bash
POST /api/report
Content-Type: application/json
{"key": "cpu_usage", "value": 75.5}
```

### 获取所有Key
```bash
GET /api/keys
```

### 获取数据
```bash
GET /api/data?key=cpu_usage&limit=100
```

## 测试
```bash
pytest tests/test_app.py -v
```