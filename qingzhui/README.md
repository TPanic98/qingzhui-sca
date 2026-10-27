# Qingzhui SCA 开发指南

本项目基于官方 Dependency-Track **5.2.1**。当前只准备源码、工具链和开发启动方式，业务定制从后续需求开始。

| 仓库 | 本地目录 | 定制分支 | 官方上游 |
| --- | --- | --- | --- |
| [qingzhui-sca](https://github.com/TPanic98/qingzhui-sca) | `backend/` | `qingzhui-main` | [dependency-track](https://github.com/DependencyTrack/dependency-track) |
| [qingzhui-sca-frontend](https://github.com/TPanic98/qingzhui-sca-frontend) | `frontend/` | `qingzhui-main` | [frontend](https://github.com/DependencyTrack/frontend) |

在各仓库中，`origin` 指向个人 fork，`upstream` 指向对应官方仓库。前端是从官方重新创建的 fork，本地源码也从官方 `5.2.1` 重新检出。

原有前端定制仓库保存为 [qingzhui-sca-frontend-backup](https://github.com/TPanic98/qingzhui-sca-frontend-backup)，其 `master` 和提交历史保持不变。经确认，该备份仓库已脱离官方 fork 网络；新前端仓库保留官方 fork 关系，后续更新在新仓库中进行。旧仓库完整 Git 镜像和两条历史 PR 的导出保存在本机 `.runtime/backups/frontend-before-refork/`。

## 工作区与工具

两个 Git 仓库并列放在同一个目录下：

```text
qingzhui/
  AGENTS.md
  README.md
  backend/
  frontend/
  .runtime/    # 工具、Docker 虚拟机、构建缓存、日志和开发数据
```

上游要求 JDK 25+、Maven 3.9+、Node.js 22+、npm 10+、Docker 和 Buf。当前 Intel Mac 的 Java、Maven、Docker CLI、Compose、Colima、Lima 和 Buf 使用官方预编译包，版本及 SHA256 固定在 `toolchains.lock.json`。Node.js/npm 使用机器上已有的 Node 22 环境。

以下命令在工作区 `qingzhui/` 中执行。

```bash
# 重建本机工具链；已完成安装时可跳过。
python3 backend/qingzhui/bootstrap-macos.py

# 启动工作区专用的 Docker 虚拟机。
bash backend/qingzhui/dev.sh containers-start

# 验证工具与 Docker 服务。
bash backend/qingzhui/dev.sh doctor
```

工具链不会修改 shell 配置文件。需要在当前终端使用这些工具时，执行：

```bash
source backend/qingzhui/env.sh
```

其他操作系统或处理器架构请按上游 `DEVELOPING.md` 安装工具，再采用对应主机的 Docker 配置；上述引导脚本专门用于当前 Intel Mac。

## 构建与启动

```bash
bash backend/qingzhui/dev.sh frontend-install
bash backend/qingzhui/dev.sh backend-build
bash backend/qingzhui/dev.sh frontend-build
```

使用两个终端分别启动后端和前端源码：

```bash
# 终端 1：后端；上游 dev-services 会自动创建开发 PostgreSQL 和前端容器。
bash backend/qingzhui/dev.sh backend-dev
```

```bash
# 终端 2：前端源码，支持热更新，并代理请求到本机后端。
bash backend/qingzhui/dev.sh frontend-dev
```

| 服务 | 地址 |
| --- | --- |
| 后端 API | <http://localhost:8080> |
| 后端就绪检查 | <http://localhost:9000/health/ready> |
| 5.2.1 前端容器 | <http://localhost:8081> |
| 前端源码热更新 | <http://localhost:8082> |
| 开发 PostgreSQL | `localhost:15432`，数据库 `qingzhui` |

开发数据库使用独立的 PostgreSQL 18 容器。15432 避开了本机已使用的 5432；此环境不连接现有 4.7.1 实例的数据库。开发模式采用上游的本地测试账号、密码和配置，只用于本机开发。生产升级需另外按官方 v4 到 v5 迁移指南执行。

空数据库首次初始化后的登录账号和密码均为 `admin`，首次登录会要求修改密码。数据库连接用户和密码均为 `dtrack`。

停止前后端进程可在各终端按 Ctrl-C；再停止 Docker 虚拟机可释放内存：

```bash
bash backend/qingzhui/dev.sh containers-stop
```

容器复用已开启，停止虚拟机后开发数据库仍保存在 `.runtime/` 中。初次启动需要下载容器镜像；初次构建需要下载 Maven/npm 依赖。

前端构建会生成 `src/version.json` 和 `dist/` 等产物。提交业务改动时核对这些生成文件，按上游约定处理。

## 获取官方更新

GitHub fork 关系已经保留，后续通过 `upstream` 获取并合并官方新版本，无需重新 fork。两个仓库各自导入新版本。

```bash
bash backend/qingzhui/dev.sh upstream-fetch
```

先查看官方发布记录、版本迁移说明和两个仓库的 tag。选定真实发布的目标 tag 后，在每个仓库分别执行以下流程：

```bash
cd backend  # 前端则进入 frontend
git switch qingzhui-main
git status --short

# 将这里的字符串改为官方已发布、已经核查的版本标签。
NEW_TAG='实际已发布的版本标签'
git switch -c "update/upstream-${NEW_TAG}"
git merge --no-ff "$NEW_TAG"
```

从干净工作区开始，解决冲突后运行对应构建、测试及数据库迁移验证。验证通过，再把集成分支合并回 `qingzhui-main` 并推送到个人 fork。`backend/qingzhui/` 集中了本次工作区辅助文件，便于后续识别定制内容。

官方 `main` 通常还包含未发布的开发提交；当前工作区按发布 tag 选择稳定基线。保留官方 tag 和原始分支，使用独立分支维护定制提交。

## 后续开发

在对应仓库内创建功能分支，并遵循该仓库的 `AGENTS.md`、`DEVELOPING.md` 和提交规范。后端通过上游 `make` 目标构建；自动化调用时传入 `AGENT=1`。具体功能、测试范围和产品命名调整由后续需求确定。
