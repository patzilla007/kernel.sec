# ——— 在宿主机（Ubuntu 24.04）上安装 Docker ———
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker run --rm hello-world  # 验证安装

# ——— 拉取镜像并启动容器，挂载内核源码路径 ———
sudo docker pull ubuntu:22.04
sudo docker run -it --rm \
  -v ~/Desktop/easylkb/kernel/linux-6.6.92:/kernel \
  ubuntu:22.04 bash

# —— 以下为容器内操作 —— #
apt update
apt install -y build-essential libncurses-dev bison flex libssl-dev libelf-dev bc wget
cd /kernel

# 1) 如果没有 .config，先生成默认配置
make defconfig

# 2) 如果想用宿主机原有配置，可： cp /boot/config-$(uname -r) .config && make olddefconfig

# 3) 编译内核及模块
make -j$(nproc)

# 如果需要单独安装模块：
# make modules_install INSTALL_MOD_PATH=/kernel/modules-out

# 如果需要压缩内核镜像：
# make bzImage

# 如果需要打包成 Debian 包：
# make -j$(nproc) bindeb-pkg
# cp ../*.deb /kernel

# 编译结束后，退出容器（exit），宿主机上的 ~/Desktop/easylkb/kernel/linux-6.6.92 下即可看到所有编译产物。
