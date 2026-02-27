#!/bin/bash
# 趋势展示服务器部署脚本
# 部署到 /srv/trend-server

set -e

INSTALL_DIR="/srv/trend-server"
SERVICE_NAME="trend-server"
PORT=9800

echo "=== 趋势展示服务器部署 ==="

# 1. 创建部署目录
echo "[1/7] 创建部署目录..."
sudo mkdir -p $INSTALL_DIR
sudo chown $USER:$USER $INSTALL_DIR

# 2. 复制项目文件
echo "[2/7] 复制项目文件..."
cp -r app.py config.py models.py requirements.txt templates/ static/ 2>/dev/null || true
cp -r app.py config.py models.py requirements.txt templates/ $INSTALL_DIR/ 2>/dev/null || true

# 3. 创建 Python 虚拟环境
echo "[3/7] 创建 Python 虚拟环境..."
cd $INSTALL_DIR
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# 4. 安装依赖
echo "[4/7] 安装依赖..."
source $INSTALL_DIR/venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
pip install gunicorn -q

# 5. 创建 systemd 服务
echo "[5/7] 创建 systemd 服务..."
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=Trend Server
After=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$INSTALL_DIR
Environment="PATH=$INSTALL_DIR/venv/bin"
ExecStart=$INSTALL_DIR/venv/bin/gunicorn -w 4 -b 0.0.0.0:$PORT app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 6. 配置防火墙
echo "[6/7] 配置防火墙..."
sudo ufw allow $PORT/tcp 2>/dev/null || echo "ufw 未启用或已允许"
sudo ufw reload 2>/dev/null || true

# 7. 启动服务
echo "[7/7] 启动服务..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# 验证状态
echo ""
echo "=== 部署完成 ==="
echo "服务状态:"
sudo systemctl status $SERVICE_NAME --no-pager | grep -E "(Active|Loaded|Main PID)" || true
echo ""
echo "访问地址: http://$(hostname -I | awk '{print $1}'):$PORT"
echo "API 地址: http://$(hostname -I | awk '{print $1}'):$PORT/api/report"
echo ""
echo "常用命令:"
echo "  sudo systemctl status $SERVICE_NAME    # 查看状态"
echo "  sudo systemctl restart $SERVICE_NAME   # 重启服务"
echo "  sudo systemctl stop $SERVICE_NAME      # 停止服务"
echo "  sudo journalctl -u $SERVICE_NAME -f    # 查看日志"