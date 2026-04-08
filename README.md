# InternTracker (macOS)

一个原生 macOS SwiftUI 应用，用于按日历记录实习方式（线下/远程），并自动统计出勤与预估薪资。

## 功能

- 月历视图，点击日期循环切换：未标记 -> 线下 -> 远程
- 当月统计：线下天数、远程天数、总出勤天数
- 薪资计算：
  - 月基础薪资
  - 每月计薪工作日
  - 线下/远程补贴
  - 自动计算预估薪资
- 本地持久化（自动保存）

## 预估薪资计算逻辑

```text
基础日薪 = 月基础薪资 / 每月计薪工作日
预估薪资 = 总出勤天数 * 基础日薪 + 线下天数 * 线下补贴 + 远程天数 * 远程补贴
```

## 运行方式

### 方式 1：命令行一键运行

```bash
chmod +x run_app.sh
./run_app.sh
```

这个脚本会自动选择兼容的 macOS SDK，用 `swiftc` 直接编译并启动应用。

### 方式 2：标准 SwiftPM 命令

```bash
swift run
```

## 打包为 .app 和 zip（不依赖 Xcode）

```bash
chmod +x package_app.sh
./package_app.sh
```

打包后产物：

- `dist/InternTracker.app`
- `dist/InternTracker.zip`

你可以直接双击 `dist/InternTracker.app` 运行。

如果要发给别人，首次打开可能会被 Gatekeeper 拦截（因为只是本地 ad-hoc 签名）。
对外分发通常还需要：

- Apple Developer 证书签名
- 公证（notarization）

## 问题

如果出现如下错误：

- `swift run` 直接 abort
- `dyld Symbol not found ... swift-package ... llbuild`

说明 Command Line Tools 的 `swift-package` 与 `llbuild` 二进制不匹配。

在修复工具链前，优先使用 `./run_app.sh`，不依赖 `swift run`。

## 数据存储路径

应用将数据保存在：

- `~/Library/Application Support/InternTracker/attendance_data.json`
