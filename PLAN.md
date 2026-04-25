# Plan: Agent Master Companion — macOS 状态栏工具

## Context

创建一个独立的 macOS 状态栏（menubar）工具，名为 Agent Master Companion。定位为 agent 使用场景的轻量辅助工具，常驻状态栏，不占 Dock 位。与 agent-master 知识库仓库完全独立，无工程依赖。

## 决策

- 独立仓库：`agent-master-companion`
- 技术栈：Swift + SwiftUI（UI）+ AppKit（menubar/tray 集成）
- 平台：仅 macOS
- 形态：状态栏常驻工具，点击弹出 popover 面板
- 预留后续打开独立桌面窗口的入口

## Agent 文件类型清单（调研结果）

### 项目级指令文件（Project-level Instructions）

| 工具 | 文件/目录 | 说明 |
|------|-----------|------|
| Claude Code | `CLAUDE.md` | 项目指令，自动加载 |
| Claude Code | `.claude/settings.json` | 项目配置（权限、hooks、环境变量） |
| Claude Code | `.claude/settings.local.json` | 本地覆盖配置 |
| Claude Code | `.claude/memory/` | 自动记忆文件 |
| Claude Code | `.claude/plans/` | 任务计划 |
| Codex / Augment | `AGENTS.md` | 项目级 agent 指令（层级式） |
| Codex | `codex.md` | 替代指令格式 |
| Cursor | `.cursorrules` | AI 行为指令 |
| Cursor | `.cursor/rules/` | 模块化规则目录 |
| Windsurf | `.windsurfrules` | Cascade AI 行为配置 |
| GitHub Copilot | `.github/instructions/*.instructions.md` | 命名指令文件（支持 applyTo glob） |
| GitHub Copilot | `.github/copilot-instructions.md` | 旧格式（已废弃） |
| Cline | `.clinerules` | 单文件指令（旧格式） |
| Cline | `.clinerules/` | 模块化指令目录 |
| Roo Code | `.roomodes` | JSON 自定义模式配置 |
| Roo Code | `.roo/` | 项目配置目录 |
| Aider | `.aider.conf.yaml` | 项目配置 |
| Aider | `.aiderignore` | 忽略文件 |
| Continue.dev | `.continue/config.ts` / `.yaml` / `.json` | 项目配置 |
| Amazon Q | `.amazonq/rules/*.md` | 规则文件目录 |
| Augment | `.augment-guidelines` | 指导文件 |
| Devin | `.devin/config.json` | 项目配置 |
| Devin | `.devin/rules.md` | 项目规则 |

### 用户级全局文件（User-level Global）

| 工具 | 路径 | 说明 |
|------|------|------|
| Claude Code | `~/.claude/settings.json` | 全局设置 |
| Claude Code | `~/.claude/keybindings.json` | 快捷键 |
| Claude Code | `~/.claude/projects/` | 按项目组织的记忆 |
| Codex | `~/.config/codex/config.toml` | 全局配置 |
| Aider | `~/.aider.conf.yaml` | 全局配置 |
| Aider | `~/.aiderignore` | 全局忽略 |
| Continue.dev | `~/.continue/config.ts` / `.yaml` | 全局配置 |
| Devin | `~/.config/devin/config.json` | 全局配置 |

### 运行时生成文件（Runtime/Generated）

| 工具 | 路径 | 说明 |
|------|------|------|
| Claude Code | `.claude/memory/*.md` | 自动积累的项目上下文 |
| Claude Code | `.claude/plans/*.md` | 会话计划与任务追踪 |
| Cline | Memory Bank files | 结构化文档（持久上下文） |

## MVP 功能

### 1. Agent 文件浏览器（核心功能）

#### 项目维度扫描
- 通过 NSOpenPanel 选择项目文件夹
- 递归扫描识别上述所有项目级 agent 文件和目录
- 按工具分组展示（Claude Code / Cursor / Copilot / ...）
- 树形展示，支持查看和编辑
- 记住最近打开的项目
- 跳过：`node_modules`, `.git`, `dist`, `build`, `target`

#### 用户维度扫描
- 自动发现用户级全局 agent 配置文件
- 扫描 `~/.claude/`, `~/.config/codex/`, `~/.continue/`, `~/.aider.conf.yaml` 等
- 展示当前机器上安装了哪些 agent 工具及其全局配置状态

#### 文件识别注册表
- 维护一份可扩展的 agent 文件模式注册表（AgentFileRegistry）
- 每条记录包含：工具名、文件模式（glob）、层级（project/user/runtime）、说明
- 后续可通过配置文件或远程更新扩展新工具支持

### 2. 临时草稿板（附加功能）
- 持久化记事本，在等待 agent 响应时随时记录想法
- 笔记自动保存
- 笔记列表管理（增删查）
- Prompt Composer：勾选多条笔记 → 组合 → 复制到剪贴板

## 技术架构

```
agent-master-companion/
  AgentMasterCompanion.xcodeproj
  AgentMasterCompanion/
    App.swift                     — @main, NSApplication 配置，隐藏 Dock 图标
    AppDelegate.swift             — NSStatusItem 创建，popover 管理
    Views/
      ContentView.swift           — popover 主视图，tab 切换
      Explorer/
        ProjectPickerView.swift
        AgentFileTreeView.swift
        FileViewerView.swift
      ScratchPad/
        ScratchPadView.swift
        NoteListView.swift
        PromptComposerView.swift
    Models/
      AgentFile.swift             — agent 文件模型
      AgentTool.swift             — agent 工具定义（Claude, Cursor, Copilot...）
      AgentFileRegistry.swift     — 文件模式注册表（可扩展）
      Note.swift                  — 笔记模型
      Project.swift               — 项目模型
    Services/
      FileScanner.swift           — agent 文件发现逻辑（项目级 + 用户级）
      StorageService.swift        — 持久化（JSON 文件）
    Resources/
      Assets.xcassets             — 状态栏图标
  README.md
  CLAUDE.md
```

## 关键实现细节

### 状态栏集成
- `NSStatusItem` + `NSPopover` 实现点击弹出面板
- `LSUIElement = true`（Info.plist）隐藏 Dock 图标
- popover 尺寸约 400x500，可调整
- 预留 "Open in Window" 按钮，后续支持独立窗口模式

### 文件系统访问
- `NSOpenPanel` 选择文件夹（项目级扫描的入口）
- `FileManager` 递归遍历
- 非沙盒应用（开发工具性质，需要访问任意项目目录和用户级 dotfiles）

### 分发策略

#### 构建产物
- **Universal Binary**（arm64 + x86_64）：一个包同时支持 Intel 和 Apple Silicon Mac
- 体积增加约 10-15%，对轻量 menubar 工具可忽略
- 无需芯片检测、无需维护双包、用户无需选择架构

#### 分发格式
- **DMG**：macOS 用户最熟悉的格式，拖拽到 Applications 安装
- 不用 PKG（暗示系统级安装，对 menubar 工具过重）
- 不用 ZIP（体验不够精致）
- 不用 bootstrap installer（应用本身轻量，无额外组件）

#### 演进路径

v0（首发）：
- 产物：`AgentMasterCompanion-universal.dmg`（未签名）
- 渠道：GitHub Releases
- 用户首次打开需右键 > 打开绕过 Gatekeeper
- README 中提供清晰的安装说明和 Gatekeeper 绕过指引

v1（成熟后）：
- 产物：`AgentMasterCompanion-universal.dmg`（签名+公证）+ `.zip`（Sparkle 自动更新用）
- 渠道：GitHub Releases + Homebrew Cask + Sparkle 自动更新
- 需要 Apple Developer Program（$99/年）
- 集成 Sparkle 2 框架实现静默后台更新

#### DMG 制作
- 使用 `create-dmg` 或 `hdiutil` 生成带背景图和 Applications 快捷方式的 DMG
- Xcode Archive → Export → 打包为 DMG

### 产品能力边界与隐私设计

#### 核心定位
本工具仅浏览和管理"指令/上下文/规则"类 agent 文件，**不触碰任何可能含凭证的配置文件**。这是产品功能边界，不是技术限制。

#### 文件分类（白名单机制）

仅操作的文件类型（非敏感，纯文本/Markdown）：
- 指令文件：`CLAUDE.md`, `AGENTS.md`, `codex.md`, `.cursorrules`, `.windsurfrules`, `.clinerules`, `.roomodes`, `.augment-guidelines`, `.devin/rules.md`
- 指令目录：`.cursor/rules/`, `.clinerules/`, `.amazonq/rules/`, `.github/instructions/`
- 上下文文件：`.claude/memory/*.md`, `.claude/plans/*.md`
- 忽略规则：`.aiderignore`

明确排除的文件类型（敏感，可能含凭证）：
- `.claude/settings.json`, `.claude/settings.local.json`
- `.aider.conf.yaml`, `~/.aider.conf.yaml`
- `~/.config/codex/config.toml`
- `.continue/config.*`
- `.devin/config.json`
- 任何 `settings.*`, `config.*`, `*.key`, `*.pem`, `*.env` 模式

#### 设计原则
1. **白名单准入**：只有注册表中明确标记为"非敏感"的文件模式才会被扫描和展示
2. **本地优先，零网络**：应用不联网，不上传任何数据
3. **只读默认**：编辑需用户显式切换
4. **不缓存文件内容**：仅缓存文件路径和元数据
5. **无遥测**：不收集任何使用数据

#### 隐私声明
在 README 和应用内 About 中明确声明：
- 应用完全离线运行，不发送任何网络请求
- 仅浏览指令/上下文/规则类文件，不读取任何配置或凭证文件
- 不收集、不上传、不缓存用户文件内容
- 源代码开源，可审计

### 数据持久化
- 笔记和最近项目：存储为 JSON 文件到 `~/Library/Application Support/AgentMasterCompanion/`
- 使用 `Codable` 协议序列化

## 实施步骤

### Phase 0: Harness 环境搭建（第一优先级，在写任何代码之前）

#### 0.1 工作空间设置
- 创建 VS Code multi-root workspace 文件（如 `~/agent-workspace.code-workspace`），同时包含 `agent-master` 和 `agent-master-companion` 两个根目录
- 两个仓库各自独立（独立 git、独立 CLAUDE.md），但开发者可在同一编辑器中交叉参考
- Claude Code 按各自根目录加载对应的 CLAUDE.md，互不干扰

#### 0.2 新仓库初始化（先建 harness，再建代码）
1. 创建 `agent-master-companion` 仓库，初始化 git
2. 编写 `CLAUDE.md`——新项目的核心 agent 上下文，包含：
   - 项目定位：macOS 状态栏工具，Swift/SwiftUI + AppKit
   - 目录结构说明
   - 构建命令（xcodebuild）
   - commit 前缀约定（适配 Swift 项目：`feat:`, `fix:`, `infra:`, `ui:`, `build:`, `docs:`）
   - 安全边界：白名单文件机制、不触碰敏感配置
   - 开发者背景声明：零 macOS 客户端经验，agent 需要提供更详细的解释和指导
3. 从 agent-master 复用规则（复制并适配，不用 submodule）：
   - `rules/git-workflow.md` → 适配 Swift 项目的分支和 commit 前缀
   - `rules/pii-protection.md` → 直接复用
   - `rules/honest-error-handling.md` → 直接复用
   - `rules/external-system-diagnosis.md` → 适配 Xcode/macOS 场景
4. 创建新项目特有的规则：
   - `rules/file-access-boundary.md` — 白名单文件机制，明确哪些文件可操作
   - `rules/swift-conventions.md` — Swift/SwiftUI 编码约定（由 agent 在开发过程中逐步补充）
5. 创建 `.gitguard` — 敏感模式拦截（复用 agent-master 的模式）

#### 0.3 反向驱动 agent-master
在新项目开发过程中，识别 agent-master 缺失的通用实践并反向补充：
- 如果发现 git-workflow 规则需要更通用的 commit 前缀体系 → 更新 agent-master
- 如果发现 macOS 原生开发的 agent 指导有通用价值 → 作为新内容贡献回 agent-master
- 如果发现 agent-master 的规则/技能分发机制不够便捷 → 驱动改进分发方式

### Phase 1: 项目脚手架
1. 创建 Xcode 项目（macOS App, SwiftUI, Swift）
2. 配置为 menubar-only app（LSUIElement, NSStatusItem）
3. 实现基础 popover 弹出/收起
4. 创建 Git 仓库，编写 CLAUDE.md 和 README

### Phase 2: Agent 文件浏览器
5. 实现 `AgentTool` + `AgentFileRegistry` — 文件模式注册表
6. 实现 `FileScanner` — 项目级递归扫描 + 用户级全局扫描
7. 实现 `AgentFile`/`Project` 模型
8. 构建 `ProjectPickerView`（NSOpenPanel + 最近项目列表）
9. 构建 `AgentFileTreeView`（OutlineGroup 树形展示，按工具分组）
10. 构建 `FileViewerView`（TextEditor 查看/编辑）
11. 实现用户级扫描视图（展示全局 agent 配置状态）

### Phase 3: 临时草稿板
10. 实现 `StorageService` + `Note` 模型
11. 构建 `ScratchPadView`（TextEditor + 自动保存）
12. 构建 `NoteListView`（List + 删除）
13. 构建 `PromptComposerView`（多选 + 复制）

### Phase 4: 收尾
14. 状态栏图标设计
15. 暗色/亮色主题适配（跟随系统）
16. 全局快捷键唤起 popover
17. 测试

## Verification

- 应用启动后仅出现在状态栏，不出现在 Dock
- 点击状态栏图标弹出 popover 面板
- Agent 文件浏览器：选择文件夹 → 树形展示 → 查看/编辑文件
- 草稿板：写笔记 → 退出重开 → 笔记持久化 → 选择笔记 → 复制为 prompt
- agent-master 仓库无任何改动
