#!/bin/bash
# ============================================
# 两弹一星精神宣传网 - 一键部署脚本
# 合肥工业大学 · 核炬薪传宣讲团
# ============================================
set -e

echo "============================================"
echo "  两弹一星精神宣传网 - 开始部署"
echo "============================================"

# 1. 安装 nginx 和 unzip
echo "[1/5] 安装 Nginx 和 unzip..."
apt update -y >/dev/null 2>&1
apt install -y nginx unzip >/dev/null 2>&1
echo "  ✓ Nginx 安装完成"

# 2. 创建网站目录并解压
echo "[2/5] 部署网站文件..."
SITE_DIR="/var/www/liangdan-yixing"
rm -rf "$SITE_DIR"
mkdir -p "$SITE_DIR"

# 查找 zip 文件（支持中英文文件名）
ZIP_FILE=""
for f in /root/*.zip /tmp/*.zip ./*.zip; do
  if [ -f "$f" ]; then
    ZIP_FILE="$f"
    break
  fi
done

if [ -z "$ZIP_FILE" ]; then
  echo "  ✗ 未找到网站 zip 文件！请先上传 zip 文件到 /root/ 目录"
  exit 1
fi

echo "  解压: $ZIP_FILE"
unzip -o "$ZIP_FILE" -d "$SITE_DIR" >/dev/null 2>&1

# 如果解压后多了一层子目录，把内容提上来
SUBDIR=$(find "$SITE_DIR" -maxdepth 1 -type d | tail -1)
if [ -d "$SUBDIR" ] && [ "$(ls -A $SUBDIR 2>/dev/null)" ]; then
  # 检查是否有 pages 目录在子目录里
  if [ -d "$SUBDIR/pages" ]; then
    cp -r "$SUBDIR"/* "$SITE_DIR"/ 2>/dev/null || true
  fi
fi

# 确保文件存在
if [ ! -d "$SITE_DIR/pages" ]; then
  echo "  ✗ 未找到 pages 目录，请检查 zip 文件内容"
  echo "  当前目录内容:"
  ls -la "$SITE_DIR"
  exit 1
fi

# 设置权限
chown -R www-data:www-data "$SITE_DIR"
chmod -R 755 "$SITE_DIR"
echo "  ✓ 网站文件已部署到 $SITE_DIR"

# 3. 配置 Nginx
echo "[3/5] 配置 Nginx..."
cat > /etc/nginx/sites-available/liangdan-yixing <<'NGINX_CONF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/liangdan-yixing;
    index index.html;

    server_name _;

    # 首页指向 pages/index.html
    location = / {
        try_files /pages/index.html =404;
    }

    # 静态资源
    location / {
        try_files $uri $uri/ =404;
    }

    # 图片缓存
    location ~* \.(jpg|jpeg|png|gif|ico|webp|svg|css|js)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    # 错误页面
    error_page 404 /pages/index.html;
}
NGINX_CONF

# 启用站点，禁用默认站点
ln -sf /etc/nginx/sites-available/liangdan-yixing /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 测试配置
nginx -t >/dev/null 2>&1
echo "  ✓ Nginx 配置完成"

# 4. 启动 Nginx
echo "[4/5] 启动 Nginx..."
systemctl restart nginx
systemctl enable nginx >/dev/null 2>&1
echo "  ✓ Nginx 已启动并设为开机自启"

# 5. 获取公网IP
echo "[5/5] 获取服务器公网IP..."
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ip.sb 2>/dev/null || echo "你的公网IP")

echo ""
echo "============================================"
echo "  ✓ 部署完成！"
echo "============================================"
echo ""
echo "  访问地址: http://$PUBLIC_IP"
echo ""
echo "  ⚠️  重要：请在阿里云控制台开放 80 端口："
echo "     ECS管理 → 安全组 → 配置规则 → 添加入方向规则"
echo "     端口范围: 80/80  授权对象: 0.0.0.0/0"
echo ""
echo "  开放端口后即可通过 http://$PUBLIC_IP 访问网站"
echo "============================================"
