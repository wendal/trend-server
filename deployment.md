# 部署文档

## 环境要求
- Python 3.8+
- Linux/macOS/Windows

## 开发环境部署

```bash
cd trend-server
pip install -r requirements.txt
python app.py
```

服务将在 http://localhost:9800 启动

## 生产环境部署

### 使用 Gunicorn

```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:9800 "app:app"
```

### 使用 Docker

```dockerfile
FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 9800
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:9800", "app:app"]
```

```bash
docker build -t trend-server .
docker run -d -p 9800:9800 trend-server
```

### 使用 Systemd

创建 `/etc/systemd/system/trend-server.service`:

```ini
[Unit]
Description=Trend Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/trend-server
ExecStart=/usr/bin/python3 /opt/trend-server/app.py
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable trend-server
sudo systemctl start trend-server
```

## 配置 Nginx 反向代理

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:9800;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 测试

```bash
pytest tests/test_app.py -v
```

## 数据上报示例

```bash
curl -X POST http://localhost:9800/api/report \
  -H "Content-Type: application/json" \
  -d '{"key": "cpu_usage", "value": 75.5}'
```