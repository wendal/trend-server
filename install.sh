#!/bin/bash
# 趋势展示服务器 - 一键部署脚本
# 自动克隆代码并部署到 /srv/trend-server

set -e

INSTALL_DIR="/srv/trend-server"
SERVICE_NAME="trend-server"
PORT=9800
REPO_URL="https://github.com/wendal/trend-server.git"

echo "=========================================="
echo "   趋势展示服务器 - 一键部署"
echo "   端口：$PORT"
echo "   目录：$INSTALL_DIR"
echo "=========================================="
echo ""

# 检查是否以 root 运行
if [ "$EUID" -eq 0 ]; then
    echo "错误：请不要以 root 身份运行此脚本"
    echo "请使用普通用户执行，脚本会自动调用 sudo"
    exit 1
fi

# 1. 创建部署目录
echo "[1/8] 创建部署目录..."
sudo mkdir -p $INSTALL_DIR
sudo chown $USER:$USER $INSTALL_DIR

# 2. 克隆代码
echo "[2/8] 克隆代码..."
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "    检测到已有代码，执行 git pull..."
    cd $INSTALL_DIR
    git pull
else
    git clone $REPO_URL $INSTALL_DIR
    cd $INSTALL_DIR
fi

# 3. 创建 Python 虚拟环境
echo "[3/8] 创建 Python 虚拟环境..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "    虚拟环境创建完成"
else
    echo "    虚拟环境已存在"
fi

# 4. 安装依赖
echo "[4/8] 安装依赖..."
source $INSTALL_DIR/venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
pip install gunicorn -q
deactivate

# 5. 创建 systemd 服务
echo "[5/8] 创建 systemd 服务..."
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
echo "[6/8] 配置防火墙..."
if command -v ufw &> /dev/null; then
    sudo ufw allow $PORT/tcp 2>/dev/null && sudo ufw reload 2>/dev/null && echo "    防火墙规则已添加" || echo "    ufw 未启用，跳过"
else
    echo "    未检测到 ufw，跳过"
fi

# 7. 初始化数据库并启动服务
echo "[7/8] 启动服务..."
cd $INSTALL_DIR
source venv/bin/activate
python3 -c "from app import app, db; app.app_context().push(); db.create_all()"
deactivate
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME
sleep 2

# 8. 验证
echo "[8/8] 验证服务..."
SERVICE_STATUS=$(sudo systemctl is-active $SERVICE_NAME)
if [ "$SERVICE_STATUS" = "active" ]; then
    echo "    服务启动成功 ✓"
else
    echo "    服务启动失败 ✗"
    echo ""
    echo "查看日志：sudo journalctl -u $SERVICE_NAME -n 50"
    exit 1
fi

# 获取服务器 IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "=========================================="
echo "   部署完成 ✓"
echo "=========================================="
echo ""
echo "访问地址:"
echo "  前端界面：http://$SERVER_IP:$PORT"
echo "  前端界面：http://gz01.air32.cn:$PORT"
echo ""
echo "API 接口:"
echo "  数据上报：POST http://$SERVER_IP:$PORT/api/report"
echo "  获取数据：GET  http://$SERVER_IP:$PORT/api/data?key=xxx"
echo ""
echo "测试数据上报:"
echo "  curl -X POST http://localhost:$PORT/api/report -H 'Content-Type: application/json' -d '{\"key\":\"test\",\"value\":100}'"
echo ""
echo "常用命令:"
echo "  sudo systemctl status $SERVICE_NAME    # 查看状态"
echo "  sudo systemctl restart $SERVICE_NAME   # 重启服务"
echo "  sudo systemctl stop $SERVICE_NAME      # 停止服务"
echo "  sudo journalctl -u $SERVICE_NAME -f    # 查看日志"
echo ""