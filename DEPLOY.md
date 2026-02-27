# 服务器部署指南

## 快速部署

### 1. 上传代码到服务器

```bash
# 方式 A: 使用 git
ssh user@gz01.air32.cn
git clone https://github.com/wendal/trend-server.git /srv/trend-server
cd /srv/trend-server

# 方式 B: 使用 scp
scp -r trend-server/* user@gz01.air32.cn:/tmp/trend-server/
ssh user@gz01.air32.cn
mv /tmp/trend-server/* /srv/trend-server/
```

### 2. 执行部署脚本

```bash
cd /srv/trend-server
chmod +x deploy.sh
./deploy.sh
```

### 3. 验证部署

```bash
# 查看服务状态
sudo systemctl status trend-server

# 测试访问
curl http://localhost:9800/api/keys

# 浏览器访问
# http://gz01.air32.cn:9800
```

---

## 手动部署步骤

### 1. 创建目录
```bash
sudo mkdir -p /srv/trend-server
sudo chown $USER:$USER /srv/trend-server
cd /srv/trend-server
```

### 2. 复制代码
```bash
# 从 git 克隆
git clone https://github.com/wendal/trend-server.git .
```

### 3. 创建虚拟环境
```bash
python3 -m venv venv
source venv/bin/activate
```

### 4. 安装依赖
```bash
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn
```

### 5. 创建 systemd 服务
```bash
sudo tee /etc/systemd/system/trend-server.service > /dev/null <<EOF
[Unit]
Description=Trend Server
After=network.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=/srv/trend-server
Environment="PATH=/srv/trend-server/venv/bin"
ExecStart=/srv/trend-server/venv/bin/gunicorn -w 4 -b 0.0.0.0:9800 app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
```

### 6. 启动服务
```bash
sudo systemctl daemon-reload
sudo systemctl enable trend-server
sudo systemctl start trend-server
```

### 7. 配置防火墙
```bash
sudo ufw allow 9800/tcp
sudo ufw reload
```

---

## 常用运维命令

```bash
# 查看状态
sudo systemctl status trend-server

# 重启服务
sudo systemctl restart trend-server

# 停止服务
sudo systemctl stop trend-server

# 查看日志
sudo journalctl -u trend-server -f

# 查看错误日志
sudo journalctl -u trend-server -p err -f
```

---

## 数据备份

数据库文件位置：`/srv/trend-server/instance/trend.db`

备份命令：
```bash
cp /srv/trend-server/instance/trend.db /backup/trend-$(date +%Y%m%d).db
```

---

## 升级部署

```bash
cd /srv/trend-server
git pull
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart trend-server
```