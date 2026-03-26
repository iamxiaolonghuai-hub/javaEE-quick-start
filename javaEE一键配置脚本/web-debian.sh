#!/bin/bash
clear
echo "============================================="
echo " 🚀 Java Web 开发环境 一键自动安装工具 "
echo " 包含：JDK11 + Maven + web 命令 "
echo "============================================="

# 检查 root 权限
if [ $UID -ne 0 ]; then
    echo "❌ 请使用 sudo 运行！"
    exit 1
fi

# ==========================
# 1. 安装 JDK11
# ==========================
echo -e "\n📦 正在安装 JDK 11..."
apt update > /dev/null 2>&1
apt install -y openjdk-11-jdk > /dev/null 2>&1

# ==========================
# 2. 安装 Maven
# ==========================
echo -e "\n📦 正在安装 Maven..."
apt install -y maven > /dev/null 2>&1

# ==========================
# 3. 修复 JAVA_HOME（终极方案）
# ==========================
echo -e "\n⚙️ 配置环境变量..."
JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

echo "export JAVA_HOME=$JAVA_HOME" | tee /etc/environment /etc/profile.d/java.sh > /dev/null
echo "export M2_HOME=/usr/share/maven" | tee -a /etc/environment /etc/profile.d/java.sh > /dev/null
echo 'export PATH=$PATH:$JAVA_HOME/bin:$M2_HOME/bin' | tee -a /etc/environment /etc/profile.d/java.sh > /dev/null

chmod +x /etc/profile.d/java.sh
source /etc/environment
source /etc/profile.d/java.sh

# ==========================
# 4. 修复 web 命令（终极版）
# ==========================
echo -e "\n🔧 安装 web 快捷命令..."

cat > /usr/local/bin/web << 'EOF'
#!/bin/bash
GROUP_ID=""
ARTIFACT_ID=""
RUN_PROJECT=""

while getopts "g:p:r:" opt; do
  case $opt in
    g) GROUP_ID="$OPTARG" ;;
    p) ARTIFACT_ID="$OPTARG" ;;
    r) RUN_PROJECT="$OPTARG" ;;
    *) echo "用法："
       echo " 创建：web -g com.test -p myweb"
       echo " 运行：web -r myweb"
       exit 1 ;;
  esac
done

# 运行项目
if [ -n "$RUN_PROJECT" ]; then
  if [ ! -d "$RUN_PROJECT" ]; then
    echo "❌ 项目 $RUN_PROJECT 不存在"
    exit 1
  fi
  echo "🚀 启动项目：$RUN_PROJECT"
  cd "$RUN_PROJECT" || exit 1
  mvn jetty:run
  exit 0
fi

# 创建项目
if [ -z "$GROUP_ID" ] || [ -z "$ARTIFACT_ID" ]; then
  echo "✅ 创建：web -g com.test -p myweb"
  echo "✅ 运行：web -r myweb"
  exit 1
fi

echo "📦 生成项目：$ARTIFACT_ID"
mvn archetype:generate \
  -DgroupId="$GROUP_ID" \
  -DartifactId="$ARTIFACT_ID" \
  -DarchetypeArtifactId=maven-archetype-webapp \
  -DinteractiveMode=false

cd "$ARTIFACT_ID" || exit 1

cat > pom.xml << XML
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>$GROUP_ID</groupId>
    <artifactId>$ARTIFACT_ID</artifactId>
    <packaging>war</packaging>
    <version>1.0-SNAPSHOT</version>
    <build>
        <plugins>
            <plugin>
                <groupId>org.eclipse.jetty</groupId>
                <artifactId>jetty-maven-plugin</artifactId>
                <version>9.4.54.v20240208</version>
                <configuration>
                    <webApp>
                        <contextPath>/$ARTIFACT_ID</contextPath>
                    </webApp>
                    <httpConnector>
                        <port>8080</port>
                    </httpConnector>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
XML

echo -e "\n==================================="
echo "✅ 项目创建完成！"
echo "▶ 启动命令：web -r $ARTIFACT_ID"
echo "🌐 访问地址：http://localhost:8080/$ARTIFACT_ID"
echo "==================================="
EOF

chmod +x /usr/local/bin/web

# ==========================
# 完成
# ==========================
echo -e "\n============================================="
echo " ✅ 安装全部完成！"
echo "============================================="
echo -e "\n🔍 环境检查："
java -version
mvn -v
echo JAVA_HOME=$JAVA_HOME

echo -e "\n📌 使用方法："
echo "  创建项目：web -g com.test -p myweb"
echo "  启动项目：web -r myweb"
