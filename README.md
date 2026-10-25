# Picket Studio Overlay Distro — 基于 intellij-community 的轻量发行版构建仓

本项目不 fork 上游，只维护**极小补丁集 + GitHub Actions 流水线**：每次 CI 从上游
JetBrains/intellij-community 拉取指定 ref → 应用 patches → 用官方构建管线产出三平台发行包。

> 商标提示：本项目不叫 IntelliJ / IDEA，不使用 JetBrains logo；代码层基于 Apache 2.0 的
> intellij-community。对外发布前请阅读本文档「合规」一节。

## 仓库结构

```
.
├── .github/workflows/overlay-build.yml   # 主构建流水线（手动触发）
├── patches/                              # 补丁集（基于上游 master 生成）
│   ├── 01-product-properties.patch       # 产品名/安装名/输出名/遥测默认关闭
│   ├── 02-application-info.patch         # 应用信息（公司/全名/motto/logo）+ 新增 picket_logo.svg
│   ├── 03-brand-icons.patch              # 替换 64/16 图标（无 JetBrains 商标元素）
│   └── 04-license-notice.patch           # 替换 LICENSE.txt / NOTICE.txt 为自制发行版条款
└── scripts/
    ├── apply-patches.sh                  # 本地把 patches 应用到上游 checkout
    └── verify.sh                         # 本地 dry-run：apply + bazel query
```

## 本地验证（可选）

```bash
git clone --depth 1 https://github.com/JetBrains/intellij-community.git /tmp/community
# verify.sh 会自动拉取 android 模块（https://github.com/JetBrains/android）
bash scripts/verify.sh /tmp/community
```

## 在 GitHub Actions 上构建

1. 把本仓库推到 GitHub（`gh repo create` / `git push`）。
2. 仓库页面 Actions → **Picket Studio Overlay Build** → Run workflow。
3. 参数：
   - `upstream_ref`：上游分支或 tag。默认 `master`（与本补丁集基线一致）。
     切到稳定 tag（如 `idea/2026.2.3`）更可复现，但若补丁上下文漂移，需按第 5 节更新。
   - `os_target`：`current`（默认，仅当前 OS=linux）| `linux` | `windows` | `mac`。
   - `dry_run`：开启后只做 patch 应用 + Bazel 构建图校验，不完整构建（省时省分钟数）。

产物在 Actions Artifacts 中下载（保留 7 天）。

## 补丁内容说明

| Patch | 修改点 | 效果 |
|---|---|---|
| 01 | `IdeaCommunityProperties.kt` | 安装名/目录名/输出名改 Picket Studio；`-Didea.send.statistics=false`、`-Didea.log.upload.disabled=true` 默认注入 |
| 02 | `IdeaApplicationInfo.xml` + 新 logo | About/启动画面显示 Picket Studio，公司名 Picket Studio |
| 03 | `idea-ce.svg`、`idea-ce_16.svg` | 桌面/窗口图标替换（无商标元素） |
| 04 | `LICENSE.txt`、`NOTICE.txt` | 发行包内许可文本替换为自制发行版条款 |

**兼容性策略（重要）**：补丁刻意**不改** `platformPrefix`（保持 `Idea`）、`product` code（保持 `IDEA`）
和内置插件清单，因此 JetBrains Marketplace 插件兼容性最大化。代价是产品在插件层面仍被识别为
IDEA 社区版。若需要完全独立的 `platformPrefix`（配置目录、产品 ID 全隔离），按第 5 节扩展，
但插件兼容性会显著下降（需逐插件适配）。

## 上游升级后更新补丁（AI 辅助）

每次上游发布新版本，master 的补丁上下文可能漂移。更新流程：

1. 本机重新拉取上游对应 ref，应用旧补丁，定位失败文件：
   ```bash
   git apply --3way patches/*.patch   # 失败会指出具体文件
   ```
2. 把失败文件的「新旧内容对比 + 失败原因」交给 AI，生成新的 diff，替换对应 patch。
3. 本地 `scripts/verify.sh` 通过后提交。

## 合规要点

- 底层代码：Apache 2.0（intellij-community 各源文件头声明），可修改、分发、商用。
- 禁止：使用 IntelliJ / IntelliJ IDEA / JetBrains 商标、logo、产品名；暗示与 JetBrains 官方有关。
- 本补丁集已替换发行包内的 LICENSE/NOTICE 为自制条款（含 Apache 2.0 指引），并移除
  JetBrains 商标文案；请自行替换 README/官网等对外材料中的品牌。
- 构建仍会下载 JetBrains Runtime（JBR），发行包内含 JBR；如需自有运行时请另行处理。
- 本项目示例品牌名 Picket Studio 及 example.com 为占位，发布前请全局替换。

## 已知限制

- 完整构建资源需求高：官方 CI 需 30GB swap 防 OOM；Actions 免费额度分钟数消耗大
  （完整构建可能 1–3 小时/次），建议以 dry_run 验证为主，正式构建按需触发。
- Docker 构建环境基础镜像来自 `registry.jetbrains.team`，拉取依赖网络。
- 产物为未签名包（开源构建默认跳过签名），首次运行系统可能提示未知开发者。

## 内置插件裁剪（Picket Code 原则）

对齐 Picket Code「离线优先、最小发行」原则，patch 07 从内置插件列表中移除 13 个插件：

| 类别 | 移除插件 | 理由（对照 Picket Code） |
|---|---|---|
| 云/托管集成 | vcs-github、vcs-gitlab、repository-search | 对应 Picket Code 移除 github / github-base / github-authentication，默认离线 |
| 非核心语言/框架工具 | android-gradle-declarative-lang-ide、android-gradle-dsl、compose-ide-plugin、javaFX、eclipse（导入）、textmate-plugin | 对应语言扩展最小化；保留 Java/Kotlin/Groovy 核心语言 |
| 测试框架 | testng | 最小测试集：保留 junit，删 testng |
| 预设/基准类 | performanceTesting、keymap-eclipse、keymap-netbeans | 保留 visualStudio 键位映射，删冗余预设 |

保留：Java 全家、Kotlin、Groovy、Gradle/Maven 集成、终端、Git（vcs-git 本地）、
全部 platform-* 平台部件、markdown/json/yaml/toml/properties、MCP Server（mcpserver）、
拼写（grazie）、shell（sh-plugin）、webp 等编辑器核心。
