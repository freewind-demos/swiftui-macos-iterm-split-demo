# SwiftUI macOS iTerm Split Demo

## 简介

一个 macOS SwiftUI 桌面应用 demo。

单窗口、内部递归分屏、点击 pane 聚焦后可继续分屏，快捷键先对齐 iTerm 默认习惯：

- `Cmd + D`：左右分屏
- `Shift + Cmd + D`：上下分屏
- `Option + Cmd + R`：重置布局

## 环境

- macOS 14+
- Xcode 15+
- XcodeGen

## 运行

```bash
cd swiftui-macos-iterm-split-demo
xcodegen generate
open SwiftUIMacOSITermSplitDemo.xcodeproj
```

或命令行构建：

```bash
./scripts/build.sh
```

## 交互

1. 点击任一 pane 让它成为当前 pane
2. 按 `Cmd + D` 把当前 pane 分成左右
3. 按 `Shift + Cmd + D` 把当前 pane 分成上下
4. 新生成的 pane 会自动成为当前 pane，因此可连续分屏
