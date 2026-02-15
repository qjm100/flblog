# FLBlog - Hexo博客管理应用

一个使用Flutter框架开发的跨平台Hexo博客管理应用程序，支持Linux、Windows、macOS、Android和iOS五大操作系统平台。

## 功能特性

### 1. 文章编辑与预览系统
- 提供富文本编辑器，支持Markdown语法编写博客文章
- 实现实时预览功能，支持分屏编辑与预览模式
- 支持文章的创建、保存、修改和删除等基本操作
- 支持草稿自动保存功能

### 2. Hexo配置管理模块
- 提供可视化界面用于查看和修改Hexo配置文件(_config.yml)
- 支持配置项的分类展示和编辑
- 实现配置修改的即时验证和错误提示
- 支持配置文件的备份与恢复功能

### 3. Git集成与同步系统
- 集成Git版本控制功能，支持本地博客仓库的初始化
- 实现与GitHub仓库的连接配置
- 提供提交、拉取、推送等Git操作的可视化界面
- 支持分支管理和冲突解决功能

### 4. GitHub Pages部署自动化
- 实现GitHub Action工作流的自动配置与生成
- 支持一键部署博客到GitHub Pages
- 提供部署状态监控和日志查看功能
- 支持自定义域名配置

### 5. 主题配置管理
- 集成Hexo主题，支持在程序内快速修改主题配置
- 支持加载和保存主题配置文件

### 6. 用户界面与体验
- 采用Material Design 3 (MD3)设计规范
- 实现响应式布局，适配不同尺寸的设备屏幕
- 提供深色/浅色主题切换功能
- 优化跨平台一致性体验

### 7. 应用程序构建与发布工作流
- 创建GitHub Action工作流用于应用程序的自动化构建
- 支持为各平台生成发布版本(APK/IPA/桌面安装包)

## 项目结构

```
flblog/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── models/                      # 数据模型
│   │   ├── blog_post.dart          # 博客文章模型
│   │   ├── hexo_config.dart        # Hexo配置模型
│   │   └── git_config.dart         # Git配置模型
│   ├── providers/                   # 状态管理
│   │   └── app_provider.dart       # 应用状态提供者
│   ├── services/                    # 业务服务
│   │   ├── file_service.dart       # 文件服务
│   │   ├── yaml_service.dart       # YAML配置服务
│   │   └── git_service.dart        # Git操作服务
│   ├── screens/                     # 页面
│   │   ├── home_screen.dart        # 主页
│   │   ├── posts_screen.dart       # 文章列表
│   │   ├── editor_screen.dart      # 编辑器
│   │   ├── config_screen.dart      # 配置管理
│   │   ├── git_screen.dart         # Git管理
│   │   ├── deploy_screen.dart      # 部署管理
│   │   ├── theme_config_screen.dart # 主题配置
│   │   └── settings_screen.dart    # 设置
│   ├── widgets/                     # 组件
│   └── utils/                       # 工具函数
├── .github/
│   └── workflows/
│       └── build.yml                # GitHub Actions工作流
├── pubspec.yaml                     # 项目依赖配置
└── README.md                        # 项目说明
```

## 快速开始

### 环境要求

- Flutter SDK 3.24.0 或更高版本
- Dart SDK 3.11.0 或更高版本
- 各平台的开发环境（如Android Studio、Xcode等）

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
# 运行在桌面（Windows/Linux/macOS）
flutter run -d windows
flutter run -d linux
flutter run -d macos

# 运行在移动设备
flutter run -d android
flutter run -d ios
```

### 构建应用

```bash
# 构建Android APK
flutter build apk --release

# 构建Windows
flutter build windows --release

# 构建Linux
flutter build linux --release

# 构建macOS
flutter build macos --release

# 构建iOS
flutter build ios --release
```

## 使用说明

### 1. 配置博客目录

首次使用时，需要在"设置"页面选择你的Hexo博客目录。

### 2. 文章管理

- 在"文章"页面可以查看所有文章
- 点击"+"按钮创建新文章
- 点击文章卡片进入编辑页面
- 支持Markdown编辑和实时预览

### 3. 配置管理

- 在"配置"页面可以修改Hexo的_config.yml文件
- 支持备份和恢复配置

### 4. Git操作

- 在"Git"页面配置仓库信息
- 支持初始化、拉取、推送、提交等操作

### 5. 部署

- 在"部署"页面生成GitHub Action工作流
- 支持一键部署到GitHub Pages
- 可以配置自定义域名

### 6. 主题配置

- 在"主题"页面可以修改当前Hexo主题的配置

## 技术栈

- **框架**: Flutter
- **状态管理**: Provider
- **Markdown渲染**: flutter_markdown
- **YAML解析**: yaml, yaml_writer
- **文件选择**: file_picker
- **Git操作**: process_run
- **UI设计**: Material Design 3

## 跨平台支持

| 平台 | 支持状态 |
|------|---------|
| Android | ✅ |
| iOS | ✅ |
| Windows | ✅ |
| macOS | ✅ |
| Linux | ✅ |

## GitHub Actions自动构建

项目配置了GitHub Actions工作流，当推送标签时会自动构建所有平台的版本并创建发布。

触发构建：
```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request！

## 致谢

- [Flutter](https://flutter.dev) - 跨平台UI框架
- [Hexo](https://hexo.io) - 快速、简洁且高效的博客框架
