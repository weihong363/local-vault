# LocalVault 代码结构与关联关系

## 目录结构总览

```
lib/
├── main.dart                              # 应用入口
├── core/                                  # 核心基础设施
│   ├── constants/                       # 常量定义
│   ├── providers/                       # 全局 Provider
│   ├── services/                        # 核心服务
│   ├── utils/                           # 工具类
│   └── widgets/                        # 通用组件
└── features/                              # 功能模块
    ├── home/                           # 首页
    ├── template/                         # 模板模块
    ├── summary/                        # 摘要模块
    ├── quick_action/                   # 快捷操作
    ├── save/                           # 保存功能
    ├── search/                           # 搜索功能
    ├── settings/                         # 设置模块
    ├── inject/                           # 智能注入
    ├── gesture_config/                 # 手势配置
    └── app_whitelist/                    # 应用白名单
```

---

## 核心入口层 (lib/main.dart)

### 文件概述
应用的主入口文件，负责：
- 初始化 Flutter 应用启动
- 配置路由 (GoRouter)
- 设置全局状态 (Riverpod ProviderScope)
- 处理原生通信 (MethodChannel)
- 监听应用生命周期

### 核心依赖
- **core/constants/app_routes.dart - 路由常量
- **core/constants/app_theme.dart - 主题配置
- **core/providers/theme_provider.dart - 主题 Provider
- **core/services/share_service.dart - 分享服务
- **core/utils/storage_initializer.dart - 存储初始化
- **features/** 各功能页面

### 关键关联
```
main.dart
├── 初始化 Hive 存储
├── 配置路由 → 各功能页面
├── 设置 MethodChannel
│   ├── ↔ MainActivity.kt (Android)
│   └── ↔ QuickSaveActivity.kt (Android)
├── 初始化 ShareService
└── 监听应用生命周期
```

---

## 核心模块 (lib/core/)

### 1. 常量定义 (core/constants/)

| 文件 | 功能 | 被依赖 |
|------|------|--------|
| app_config.dart | 应用配置（版本、包名等） | main.dart, 各服务 |
| app_constants.dart | 通用常量（尺寸、动画时长等） | 各 UI 组件 |
| app_events.dart | 事件总线常量 | 各模块通信 |
| app_icons.dart | 图标常量 | 各 UI 组件 |
| app_metrics.dart | 性能指标常量 | 性能监控 |
| app_permissions.dart | 权限常量 | 权限管理 |
| app_routes.dart | 路由路径常量 | main.dart, 各页面导航 |
| app_storage.dart | 存储键常量 | 各 Repository |
| app_strings.dart | 字符串常量（多语言预留） | 各页面 |
| app_text_styles.dart | 文本样式常量 | 各 UI 组件 |
| app_theme.dart | 主题配置（浅色/深色） | main.dart, theme_provider.dart |

### 2. 全局 Provider (core/providers/)

| 文件 | 功能 | 被依赖 | 依赖 |
|------|------|--------|------|
| theme_provider.dart | 主题状态管理 | main.dart, 各页面 | app_theme.dart |
| locale_provider.dart | 语言状态管理 | main.dart, 各页面 | - |

### 3. 核心服务 (core/services/)

#### share_service.dart
- **功能**: 接收系统分享内容（文本、图片）
- **依赖**: clipboard_manager.dart, app_permissions.dart
- **被依赖**: main.dart
- **关联**:
  ```
  share_service.dart
  ├── 监听系统分享 → 触发保存页面
  └── 通知 main.dart → 跳转到 save_page.dart
  ```

#### share_sheet.dart
- **功能**: 系统分享面板集成
- **依赖**: -
- **被依赖**: -

#### clipboard_manager.dart
- **功能**: 剪贴板操作（复制、粘贴）
- **依赖**: -
- **被依赖**: share_service.dart, quick_action_page.dart
- **关联**:
  ```
  clipboard_manager.dart
  ├── 被 quick_action_page.dart 调用 → 复制模板/摘要
  └── 被 share_service.dart 调用 → 读取剪贴板
  ```

#### save_coordinator.dart
- **功能**: 快速保存协调器
- **依赖**: summary_save_service.dart
- **被依赖**: main.dart
- **关联**:
  ```
  save_coordinator.dart
  ├── 处理快速保存请求 → 调用 summary_save_service.dart
  └── 失败时 → 跳转 save_page.dart
  ```

#### summary_save_service.dart
- **功能**: 摘要保存服务
- **依赖**: summary_repository.dart
- **被依赖**: save_coordinator.dart, save_page.dart
- **关联**:
  ```
  summary_save_service.dart
  ├── 创建/更新摘要 → summary_repository.dart
  └── 被 save_page.ts 调用 → 保存用户输入
  ```

#### floating_window_service.dart
- **功能**: 悬浮窗服务（Dart 端封装）
- **依赖**: -
- **被依赖**: -
- **关联**:
  ```
  floating_window_service.dart
  ├── ↔ FloatingWindowService.kt (Android)
  └── 发送快捷操作请求 → main.dart
  ```

#### ocr_service.dart
- **功能**: OCR 文字识别服务
- **依赖**: -
- **被依赖**: -

#### accessibility_service.dart
- **功能**: 无障碍服务
- **依赖**: -
- **被依赖**: -

### 4. 工具类 (core/utils/)

| 文件 | 功能 | 被依赖 |
|------|------|--------|
| app_error_handler.dart | 全局错误处理 | main.dart |
| app_formatter.dart | 日期/时间/数字格式化 | 各页面 |
| app_logger.dart | 日志工具 | 各模块 |
| app_navigation.dart | 导航工具 | 各页面 |
| app_permission_manager.dart | 权限管理 | 各服务 |
| app_validator.dart | 输入验证 | 表单页面 |
| storage_initializer.dart | Hive 存储初始化 | main.dart |

### 5. 通用组件 (core/widgets/)

| 文件 | 功能 | 被依赖 |
|------|------|--------|
| bottom_navigation.dart | 底部导航栏 | main.dart |
| floating_save_button.dart | 浮动保存按钮 | home_page.dart |
| gesture_wake_up_detector.dart | 手势唤醒检测器 | - |
| voice_wake_up_button.dart | 语音唤醒按钮 | - |

---

## 功能模块 (lib/features/)

### 1. 首页模块 (features/home/)

#### presentation/pages/home_page.dart
- **功能**: 首页，显示摘要卡片列表，支持拖拽排序
- **依赖**:
  - summary_provider.dart - 摘要数据
  - bottom_navigation.dart - 底部导航
  - summary_card.dart - 摘要卡片组件
  - empty_state.dart - 空状态组件
- **被依赖**: main.dart（路由目标页面
- **关键实现**:
  - `_BuildReorderableItem` - 可拖拽排序的卡片组件
  - 长按缩放+阴影"抓起"效果
  - 仅长按后才允许拖拽
- **关联**:
  ```
  home_page.dart
  ├── 读取摘要列表 ← summary_provider.dart
  ├── 点击卡片 → summary_detail_page.dart
  ├── 拖拽排序 → 更新 summary_provider.dart
  └── 底部导航 → 切换到其他页面
  ```

### 2. 模板模块 (features/template/)

#### models/template.dart
- **功能**: 模板数据模型
- **依赖**: freezed, hive
- **被依赖**: template_repository.dart, template_provider.dart, template_page.dart

#### data/template_repository.dart
- **功能**: 模板数据仓库（CRUD 操作）
- **依赖**: template.dart, app_storage.dart
- **被依赖**: template_provider.dart
- **关联**:
  ```
  template_repository.dart
  ├── CRUD 操作 ↔ Hive 数据库
  └── 被 template_provider.dart 调用
  ```

#### domain/providers/template_provider.dart
- **功能**: 模板状态管理 (StateNotifierProvider)
- **依赖**: template_repository.dart
- **被依赖**: template_page.dart, quick_action_page.dart
- **关联**:
  ```
  template_provider.dart
  ├── 监听 template_repository.dart
  ├── 提供模板列表 → template_page.dart
  └── 提供模板列表 → quick_action_page.dart
  ```

#### presentation/pages/template_page.dart
- **功能**: 模板管理页面（增删改查）
- **依赖**: template_provider.dart
- **被依赖**: main.dart（路由目标）, bottom_navigation.dart
- **关键实现**:
  - `_showTemplateDialog()` - 添加/编辑模板对话框
  - 模板卡片显示标签 Chip
- **关联**:
  ```
  template_page.dart
  ├── 读取/修改模板 ↔ template_provider.dart
  └── 显示在底部导航 → bottom_navigation.dart
  ```

### 3. 摘要模块 (features/summary/)

#### models/summary.dart
- **功能**: 摘要数据模型
- **依赖**: freezed, hive
- **被依赖**: summary_repository.dart, summary_provider.dart, 各相关页面

#### data/repositories/summary_repository.dart
- **功能**: 摘要数据仓库（CRUD 操作）
- **依赖**: summary.dart, app_storage.dart
- **被依赖**: summary_provider.dart, summary_save_service.dart
- **关联**:
  ```
  summary_repository.dart
  ├── CRUD 操作 ↔ Hive 数据库
  ├── 被 summary_provider.dart 调用
  └── 被 summary_save_service.dart 调用
  ```

#### domain/providers/summary_provider.dart
- **功能**: 摘要状态管理
- **依赖**: summary_repository.dart
- **被依赖**: home_page.dart, summary_detail_page.dart, quick_action_page.dart
- **关联**:
  ```
  summary_provider.dart
  ├── 监听 summary_repository.dart
  ├── 提供摘要列表 → home_page.dart
  ├── 提供摘要详情 → summary_detail_page.dart
  └── 提供摘要列表 → quick_action_page.dart
  ```

#### presentation/pages/summary_detail_page.dart
- **功能**: 摘要详情页面
- **依赖**: summary_provider.dart
- **被依赖**: main.dart（路由目标）, home_page.dart
- **关联**:
  ```
  summary_detail_page.dart
  ├── 读取/修改摘要 ↔ summary_provider.dart
  ├── 从 home_page.dart 跳转而来
  └── 可以编辑 → 跳转到 save_page.dart
  ```

#### presentation/widgets/summary_card.dart
- **功能**: 摘要卡片组件
- **依赖**: summary.dart
- **被依赖**: home_page.dart, quick_action_page.dart

#### presentation/widgets/empty_state.dart
- **功能**: 空状态提示组件
- **被依赖**: home_page.dart, template_page.dart

### 4. 快捷操作模块 (features/quick_action/)

#### presentation/pages/quick_action_page.dart
- **功能**: 快捷操作选择界面（半透明弹窗）
- **依赖**:
  - template_provider.dart - 模板数据
  - summary_provider.dart - 摘要数据
  - clipboard_manager.dart - 剪贴板
  - MethodChannel - 原生通信
- **被依赖**: main.dart（路由目标）
- **关键实现**:
  - 支持模板选择、摘要选择、保存三种模式
  - 选择后自动复制到剪贴板
  - 关闭弹窗
- **关联**:
  ```
  quick_action_page.dart
  ├── 读取模板列表 ← template_provider.dart
  ├── 读取摘要列表 ← summary_provider.dart
  ├── 复制内容 → clipboard_manager.dart
  ├── 关闭弹窗 → MethodChannel → MainActivity.kt
  └── 从 TileService 或 FloatingWindowService 触发
  ```

### 5. 保存模块 (features/save/)

#### presentation/pages/save_page.dart
- **功能**: 保存摘要页面
- **依赖**: summary_save_service.dart
- **被依赖**: main.dart（路由目标）, share_service.dart
- **关联**:
  ```
  save_page.dart
  ├── 接收分享内容 ← share_service.dart
  ├── 保存摘要 → summary_save_service.dart
  └── 编辑模式 ← summary_detail_page.dart
  ```

### 6. 搜索模块 (features/search/)

#### presentation/pages/search_page.dart
- **功能**: 搜索页面
- **依赖**: summary_provider.dart
- **被依赖**: main.dart（路由目标）, bottom_navigation.dart
- **关联**:
  ```
  search_page.dart
  ├── 搜索摘要 ← summary_provider.dart
  └── 点击结果 → summary_detail_page.dart
  ```

### 7. 设置模块 (features/settings/)

#### presentation/pages/settings_page.dart
- **功能**: 设置页面
- **被依赖**: main.dart（路由目标）, bottom_navigation.dart

#### presentation/pages/feedback_page.dart
- **功能**: 反馈页面
- **被依赖**: settings_page.dart

#### presentation/widgets/settings_item.dart
- **功能**: 设置项组件
- **被依赖**: settings_page.dart

### 8. 智能注入模块 (features/inject/)

#### presentation/pages/inject_page.dart
- **功能**: 智能注入页面
- **被依赖**: main.dart（路由目标）

### 9. 手势配置模块 (features/gesture_config/)

#### models/gesture_config.dart
- **功能**: 手势配置数据模型
- **被依赖**: gesture_config_provider.dart, gesture_config_page.dart

#### domain/providers/gesture_config_provider.dart
- **功能**: 手势配置状态管理
- **被依赖**: gesture_config_page.dart

#### presentation/pages/gesture_config_page.dart
- **功能**: 手势配置页面
- **被依赖**: settings_page.dart

### 10. 应用白名单模块 (features/app_whitelist/)

#### models/app_info.dart
- **功能**: 应用信息数据模型
- **被依赖**: app_whitelist_provider.dart, app_whitelist_page.dart

#### domain/providers/app_whitelist_provider.dart
- **功能**: 应用白名单状态管理
- **被依赖**: app_whitelist_page.dart

#### presentation/pages/app_whitelist_page.dart
- **功能**: 应用白名单页面
- **被依赖**: settings_page.dart

---

## Android 原生层 (android/app/src/main/kotlin/com/ironion/local_vault/)

### MainActivity.kt
- **功能**: 主 Activity，处理分享、快捷方式、悬浮窗通信
- **依赖**: FlutterActivity, MethodChannel
- **关联**:
  ```
  MainActivity.kt
  ├── 接收分享 Intent → 传递给 Flutter
  ├── 处理快捷方式 → 设置 pendingAction
  ├── MethodChannel ↔ main.dart
  └── 启动 FloatingWindowService
  ```

### QuickSaveActivity.kt
- **功能**: 透明 Activity，处理快速保存
- **依赖**: FlutterActivity, MethodChannel
- **关联**:
  ```
  QuickSaveActivity.kt
  ├── 从剪贴板读取内容
  ├── MethodChannel ↔ main.dart
  └── 完成后自动 finish()
  ```

### FloatingWindowService.kt
- **功能**: 悬浮窗服务
- **依赖**: Service, WindowManager
- **关联**:
  ```
  FloatingWindowService.kt
  ├── 显示悬浮窗
  ├── 监听手势
  ├── 触发快捷操作 → MainActivity.kt
  └── MethodChannel ↔ floating_window_service.dart
  ```

### TileService 系列
| 文件 | 功能 | 关联 |
|------|------|------|
| TemplateTileService.kt | 模板快捷方式 | 启动 MainActivity, action=OPEN_TEMPLATES |
| SummariesTileService.kt | 摘要快捷方式 | 启动 MainActivity, action=OPEN_SUMMARIES |
| QuickSaveTileService.kt | 快速保存快捷方式 | 启动 MainActivity, action=QUICK_SAVE |
| InjectTileService.kt | 智能注入快捷方式 | 启动 MainActivity, action=OPEN_INJECT |
| BaseTileService.kt | 快捷方式基类 | 被以上四个继承 |

---

## 数据流向图

### 模板模块数据流
```
TemplateTileService.kt
    ↓
MainActivity.kt (pendingAction)
    ↓
main.dart (_navigateToAction)
    ↓
quick_action_page.dart
    ↓ (读取)
template_provider.dart
    ↓
template_repository.dart
    ↓
Hive 数据库
```

### 摘要模块数据流
```
SummariesTileService.kt
    ↓
MainActivity.kt (pendingAction)
    ↓
main.dart (_navigateToAction)
    ↓
quick_action_page.dart
    ↓ (读取)
summary_provider.dart
    ↓
summary_repository.dart
    ↓
Hive 数据库
```

### 保存功能数据流
```
系统分享 / QuickSaveTileService.kt
    ↓
share_service.dart / QuickSaveActivity.kt
    ↓
save_page.dart
    ↓
summary_save_service.dart
    ↓
summary_repository.dart
    ↓
Hive 数据库
```

---

## 关键技术点

### 1. 状态管理 (Riverpod)
- **全局 Provider**: `theme_provider.dart`, `locale_provider.dart`
- **功能 Provider**: `template_provider.dart`, `summary_provider.dart`, `gesture_config_provider.dart`, `app_whitelist_provider.dart`
- **使用方式**: `ref.watch() 监听变化，ref.read() 读取当前值

### 2. 路由导航 (GoRouter)
- **路由定义**: `app_routes.dart`
- **路由配置**: `main.dart` 中的 `_createRouter()`
- **导航方式**: `context.go(), context.push(), context.pop()

### 3. 本地存储 (Hive)
- **初始化**: `storage_initializer.dart`
- **数据模型**: `summary.dart`, `template.dart` (使用 HiveType)
- **Repository**: `summary_repository.dart`, `template_repository.dart`

### 4. 原生通信 (MethodChannel)
- **通道**: `com.ironion.localvault/quick_save`
- **方向**: Flutter ↔ Android
- **方法**:
  - `saveFromClipboard` - 从剪贴板保存
  - `openTemplates` - 打开模板
  - `openSave` - 打开保存
  - `openSummaries` - 打开摘要
  - `openInject` - 打开注入

### 5. 分享接收
- **ShareService**: 监听系统分享
- **Intent 过滤器: `AndroidManifest.xml` 中配置
- **数据类型: 文本、图片

---

## 开发注意事项

1. **添加新功能模块**
   - 在 `features/` 下创建新目录
   - 遵循 `presentation/` → `domain/` → `data/` 结构
   - 在 `main.dart` 中添加路由
   - 在 `app_routes.dart` 中添加路由常量

2. **添加新数据模型**
   - 使用 `freezed` 生成不可变类
   - 使用 `Hive` 注解支持持久化
   - 创建对应的 Repository 和 Provider

3. **添加新快捷方式**
   - 创建新的 `TileService`
   - 在 `AndroidManifest.xml` 中注册
   - 在 `main.dart` 中处理对应的 action

4. **主题/多语言**
   - 主题: 修改 `app_theme.dart`
   - 多语言: 修改 `app_strings.dart` (预留)

5. **Git 提交前检查
   - 运行 `dart format .`
   - 运行 `dart fix --apply`
   - 运行 `dart analyze`
   - 确保所有测试通过
