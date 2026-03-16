# LocalVault 应用开发进度

## 项目概述
一个隐私优先的本地 AI 聊天应用，类似于 Poe，但使用开源 LLM。所有数据本地存储，离线优先。

## 已完成功能

### 1. 核心架构
- [x] Flutter 项目初始化
- [x] Riverpod 状态管理配置
- [x] Hive 本地数据库集成
- [x] GoRouter 路由配置
- [x] Material 3 主题支持（深色/浅色模式）

### 2. 首页功能
- [x] 摘要卡片列表展示
- [x] 卡片拖拽排序（长按"抓起"效果：缩放+阴影变化）
- [x] 搜索功能
- [x] 空状态提示

### 3. 模板模块
- [x] 底部导航栏添加模板模块
- [x] 模板列表展示
- [x] 模板添加功能
- [x] 模板编辑功能
- [x] 模板删除功能
- [x] 模板标签显示（Chip）

### 4. 快捷操作
- [x] Android 快捷方式（TileService）
  - 模板快捷方式
  - 我的摘要快捷方式
  - 快速保存快捷方式
  - 智能注入快捷方式
- [x] 快捷操作选择界面（半透明弹窗）
- [x] 模板选择与复制
- [x] 摘要选择与复制

### 5. 保存功能
- [x] 保存页面
- [x] 文本分享接收
- [x] 图片分享接收
- [x] 快速保存（透明 Activity，无感知）
- [x] 摘要编辑功能

### 6. 设置页面
- [x] 基础设置界面
- [x] 关于页面
- [x] 手势配置页面
- [x] 应用白名单页面

### 7. 悬浮窗服务
- [x] FloatingWindowService 实现
- [x] 悬浮窗显示/隐藏
- [x] 手势监听
- [x] 快捷操作触发

## 技术栈

### 前端框架
- **Flutter 3.x** - 跨平台 UI 框架
- **Dart** - 编程语言

### 状态管理
- **flutter_riverpod** - 响应式状态管理
- **StateNotifier** - 状态变化管理

### 本地存储
- **hive_flutter** - NoSQL 本地数据库
- **path_provider** - 文件路径管理

### 路由导航
- **go_router** - 声明式路由

### UI 组件
- **Material 3** - Material Design 3 组件库
- **markdown_widget** - Markdown 渲染

### 开发工具
- **freezed** - 不可变数据类生成
- **build_runner** - 代码生成
- **flutter_test** - 测试框架

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── core/                        # 核心模块
│   ├── constants/              # 常量定义
│   ├── services/               # 服务层
│   ├── theme/                  # 主题配置
│   └── widgets/                # 通用组件
├── features/                    # 功能模块
│   ├── home/                   # 首页
│   ├── template/               # 模板模块
│   ├── settings/               # 设置模块
│   ├── quick_action/           # 快捷操作
│   ├── save/                   # 保存功能
│   └── search/                 # 搜索功能
└── shared/                      # 共享模块

android/
├── app/src/main/kotlin/
│   └── com/ironion/local_vault/
│       ├── MainActivity.kt
│       ├── QuickSaveActivity.kt
│       ├── FloatingWindowService.kt
│       ├── TemplateTileService.kt
│       ├── SummariesTileService.kt
│       ├── QuickSaveTileService.kt
│       └── InjectTileService.kt
```

## 待优化/待开发功能

### 短期优化
- [ ] 单元测试覆盖率达到 80%
- [ ] 性能优化（列表滚动、内存管理）
- [ ] 错误边界处理
- [ ] 用户体验优化（动画、反馈）

### 中期功能
- [ ] 本地 AI 推理集成（flutter_llm / onnx_runtime_flutter）
~~- [ ] 聊天界面~~
- [ ] 模型管理（下载、切换）
- [ ] 摘要总结功能
- [ ] 数据导出/导入

### 长期规划
- [ ] iOS 适配
- [ ] 多语言支持
- [ ] 主题自定义
- [ ] 数据加密（flutter_secure_storage）
- [ ] 备份与同步

## 关键文件说明

### 核心入口
- `lib/main.dart` - 应用主入口，路由配置，MethodChannel 处理

### 首页
- `lib/features/home/presentation/pages/home_page.dart` - 首页，摘要列表，拖拽排序

### 模板模块
- `lib/features/template/presentation/pages/template_page.dart` - 模板管理页面
- `lib/features/template/data/template_repository.dart` - 模板数据仓库
- `lib/features/template/domain/template_notifier.dart` - 模板状态管理

### 快捷操作
- `lib/features/quick_action/presentation/pages/quick_action_page.dart` - 快捷操作选择界面
- `android/app/src/main/kotlin/com/ironion/local_vault/TemplateTileService.kt` - 模板快捷方式服务
- `android/app/src/main/kotlin/com/ironion/local_vault/SummariesTileService.kt` - 摘要快捷方式服务

### 悬浮窗
- `android/app/src/main/kotlin/com/ironion/local_vault/FloatingWindowService.kt` - 悬浮窗服务

## 开发规范

### 代码风格
- 遵循 Effective Dart 规范
- 使用 `dart_format` 格式化代码
- 单行不超过 80 字符
- PascalCase 类名，camelCase 变量名

### 架构原则
- SOLID 原则
- MVVM 架构
- 分层设计（Presentation → Domain → Data）
- 功能模块化，独立解耦

### 状态管理
- 使用 Riverpod 进行状态管理
- UI 与逻辑分离
- 不可变数据（使用 freezed）

### Git 提交前
- 运行 `dart_fix`
- 运行 `dart analyze`
- 确保所有测试通过

## 已知问题

### 当前存在的问题（2026-03-12）

1. **** - 访问模板模块时报错，需要深入排查 Hive 存储和初始化流程
2. **同一会话里保存的多个记录无法合并** - 重复保存相同内容在重新打开后悔存在多条，并且无法做到会话记忆合并

### 已修复问题
1. ~~快捷操作后会跳转到主应用~~ → 目前使用半透明弹窗，这是 Android 系统限制
2. ~~卡片拖拽排序在某些情况下可能不流畅~~ → 已优化
3. ~~复制内容后窗口不会自动关闭~~ → 已修复
4. ~~SnackBar 不显示~~ → 已修复
5. ~~复制摘要后访问次数不增加~~ → 已修复（修正 recordAccess 调用链）
6. ~~快捷方式弹窗存在黑色色块~~ → 已修复（透明模式 + Texture 渲染）
7. ~~多次访问摘要仅增加 1 次访问数~~ → 已修复（访问次数累加逻辑）
8. ~~摘要需要压缩和标签生成~~ → 已修复（标题压缩 + 自动标签）
9. ~~模板模块访问失败~~ → 已修复（删除旧的模板实现，以及做了统一的样式处理）

概述：当前已收敛访问计数、会话合并、标题与标签生成、快捷弹窗黑块问题，仅剩模板模块访问失败待排查修复。

## 最后更新

2026-03-16
