# Quard Star 逐章实践记录

## 本地约定

- 教程：https://quard-star-tutorial.readthedocs.io/zh-cn/latest/index.html
- 上游：https://github.com/QQxiaoming/quard_star_tutorial
- 项目目录：`/home/yingsonghu/project/quard_star_tutorial`
- 环境：WSL2，Ubuntu 22.04.5 LTS，x86_64，GCC 11.4.0，Python 3.10。
- 起点：官方 `ch1` 标签，提交 `04d806c9c2ad73be7a49d6a0472c6b405662dddd`。
- 本地分支：`learning`。后续逐章在此修改；上游标签用于对照。
- 本次只做 ch0、ch1；后续章节不预先合入。

## ch0：引言与环境准备

目标是理解整条路线：用 QEMU 模拟自己的 RISC-V 开发板，再逐步实现从复位启动到运行 Linux 的过程。
QEMU 在宿主机上模拟 CPU、内存和外设；本章尚不编写 Quard Star 板级代码。

教程最初使用 Ubuntu 18.04；本次在已有的 Ubuntu 22.04 中准备依赖。
下面命令在 Ubuntu 终端执行，需要管理员权限：

```bash
sudo apt-get update
sudo apt-get install -y build-essential git python3 \
  ninja-build pkg-config libglib2.0-dev libpixman-1-dev libgtk-3-dev \
  libcap-ng-dev libattr1-dev libsdl2-dev device-tree-compiler \
  bison flex gperf intltool mtd-utils libslirp-dev
```

这些包包括编译工具、QEMU 所需库，以及教程后续使用的设备树和镜像工具。
本次已通过 Windows 的 `wsl.exe -d Ubuntu-22.04 -u root` 安装；无需重复安装。

## ch1：从源码构建 QEMU

教程明确使用 QEMU 6.0.0；上游主分支已换版本，因此从章节标签开始。
本次源码获取过程如下，现有目录已经完成，无需再次克隆：

```bash
cd /home/yingsonghu/project
git clone --depth 1 --branch ch1 \
  https://github.com/QQxiaoming/quard_star_tutorial.git quard_star_tutorial
cd quard_star_tutorial
git switch -c learning
```

仓库已包含 `qemu-6.0.0` 源码，无需再下载官网压缩包。
原有 `build.sh` 的配置参数含义：

| 参数 | 含义 |
| --- | --- |
| `--prefix=.../output/qemu` | 安装到项目目录，不覆盖系统 QEMU |
| `--target-list=riscv64-softmmu` | 构建 64 位 RISC-V 的整机模拟器 |
| `--enable-gtk` | 编入 GTK 图形界面支持 |
| `--enable-virtfs` | 编入宿主与来宾共享目录所用的 VirtFS 支持 |
| `--disable-gio` | 按教程关闭 GIO 支持 |

这里用宿主机 GCC 编译的是运行在 x86_64 Ubuntu 上的模拟器。
被模拟的 CPU 才是 RISC-V；本章还不需要 RISC-V 交叉编译器。

构建命令，在 Ubuntu 中执行：

```bash
cd /home/yingsonghu/project/quard_star_tutorial
mkdir -p output
bash -e build.sh > output/build-ch1.log 2>&1
```

保留上游脚本，使用 `bash -e` 让构建出错时立即停止。
脚本先配置，再以 `make -j16` 编译，最后安装；构建和安装不需要 root。
如需观察进度，可在另一个终端执行 `tail -f output/build-ch1.log`。

- 源码：`qemu-6.0.0/`
- 中间构建文件：`qemu-6.0.0/build/`
- 安装结果：`output/qemu/`
- 完整构建日志：`output/build-ch1.log`

验收命令：

```bash
./output/qemu/bin/qemu-system-riscv64 -version
```

首行应为 `QEMU emulator version 6.0.0`，可能附带仓库生成的版本后缀。
本章只验收模拟器编译与版本，Quard Star 板卡从 ch2 才开始添加。

注意：原始脚本按 `output/qemu` 是否存在决定是否运行 configure。
后续若修改配置参数，需要手动重新执行 configure；仅再次运行脚本不会应用新参数。

## 本次验收（2026-10-30）

- ch0：依赖安装完成，包版本记录在 `output/environment-ch0.txt`。
- ch1：原始 `build.sh` 编译、安装成功，退出码为 0；未修改 QEMU 源码和构建脚本。
- 已安装的可执行文件输出：

```text
QEMU emulator version 6.0.0
Copyright (c) 2003-2021 Fabrice Bellard and the QEMU Project developers
```

- `-machine help` 包含标准 `virt` 板；尚无自定义 Quard Star 板，符合 ch1 阶段。
- `-display help` 包含 `gtk`，`-device help` 包含 `virtio-9p`，相关功能已编入。
- 标准 `virt` 板以 `-bios none -S -display none` 启动成功；monitor 返回
  `VM status: paused`，执行 `quit` 后正常退出。
- 上述功能探测和启动验证保存于 `output/verify-ch1.txt`；未验证 GTK 窗口显示。

ch0、ch1 已完成。下一章是 ch2：在 QEMU 中添加自己的 Quard Star 仿真板。
