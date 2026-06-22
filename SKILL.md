---
name: done-alert
description: 在 macOS 上为 Claude Code 配置「任务完成提示」——任务结束(Stop)时 afplay 播放一段语音 + 在所有屏幕全屏弹出一张大图(按任意键/点击任意位置关闭，期间不会误操作电脑)。会引导用户提供自己的声音和图片，自动建目录、编译弹图程序、把 Stop hook 合并进 settings.json、校验并自测。仅限 macOS(依赖 afplay 和 swift)。触发词：装提示音、完成提示音、任务完成提醒、做个提示音、弹图提醒、setup done alert、done-alert。
---

# done-alert：任务完成语音 + 全屏弹图提醒

给 Claude Code 配一个 **Stop hook**：每次任务结束时播放语音 + 在所有屏幕弹出一张无边框大图。提示图显示期间，按任何键 / 点屏幕任何位置都只用于关闭这张图，**不会操作到电脑**；关闭后键盘鼠标立即恢复正常。**仅限 macOS**（依赖 `afplay` 和 `swift`）。

## 执行步骤（按顺序做，关键处先 Read 再改）

1. **环境检查**：确认是 macOS；`which swift` 确认有 swift。没有就提示用户运行 `xcode-select --install` 安装命令行工具后再来。

2. **建目录**：`mkdir -p ~/.claude/sounds`

3. **要素材**（问用户）：
   - **声音**（mp3/m4a/wav/aiff 均可）：让用户给文件路径，复制为 `~/.claude/sounds/done.mp3`（afplay 能放就行，扩展名是 mp3 没关系）。
   - **图片**（建议透明底 PNG）：复制为 `~/.claude/sounds/alert.png`（jpg 也行，命名 `alert.jpg`）。
   - 若用户还没准备好：告知放置路径与命名约定（`done.mp3` / `alert.png`），可先用占位图继续，之后覆盖同名文件即可，配置不用动。

4. **部署弹图程序**：把本 skill 目录下的 `show-alert.swift` 复制到 `~/.claude/sounds/show-alert.swift`，然后编译：
   ```
   cp ~/.claude/skills/done-alert/show-alert.swift ~/.claude/sounds/show-alert.swift
   swiftc -O -o ~/.claude/sounds/show-alert ~/.claude/sounds/show-alert.swift
   ```
   若 skill 目录缺该文件，用文末【附：show-alert.swift 源码】重建后再编译。

5. **合并 Stop hook** 到 `~/.claude/settings.json`：**务必先 Read，合并而非覆盖**。若已有 `hooks.Stop` 就把下面这条 command 追加进它的 hooks 数组；没有就新建 `Stop`：
   ```
   afplay $HOME/.claude/sounds/done.mp3 & IMG=$(ls $HOME/.claude/sounds/alert.* 2>/dev/null | head -1); [ -n "$IMG" ] && nohup $HOME/.claude/sounds/show-alert "$IMG" 0.7 >/dev/null 2>&1 &
   ```
   注意写进 JSON 时 `"$IMG"` 的双引号要转义为 `\"$IMG\"`。

6. **校验 + 自测**：`jq empty ~/.claude/settings.json` 确认合法 JSON；再手动跑一遍该 command（`bash -c '...'`）确认能出声 + 两屏弹图。

7. **收尾提醒**：
   - Stop hook 改动要在 Claude Code 里**打开一次 `/hooks` 菜单或重启扩展**才会在真实任务结束时生效。
   - 以后换声音/图片：直接覆盖 `~/.claude/sounds/done.mp3` 或 `~/.claude/sounds/alert.png`，配置不动。
   - 图片大小：改命令里的 `0.7`（占屏幕高度比例，可改 `0.4`~`0.9`）。

## 附：show-alert.swift 源码（skill 目录缺文件时用此重建）

```swift
import Cocoa

class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
class OverlayView: NSView {
    let img: NSImage
    let frac: CGFloat
    init(image: NSImage, frame: NSRect, frac: CGFloat) {
        self.img = image; self.frac = frac
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) { fatalError() }
    override var acceptsFirstResponder: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        let isz = img.size
        guard isz.height > 0 else { return }
        let h = bounds.height * frac
        let scale = h / isz.height
        let w = isz.width * scale
        let x = (bounds.width - w) / 2
        let y = (bounds.height - h) / 2
        img.draw(in: NSRect(x: x, y: y, width: w, height: h))
    }
    override func mouseDown(with event: NSEvent) { NSApp.terminate(nil) }
    override func rightMouseDown(with event: NSEvent) { NSApp.terminate(nil) }
    override func keyDown(with event: NSEvent) { NSApp.terminate(nil) }
}
let args = CommandLine.arguments
guard args.count > 1, let image = NSImage(contentsOfFile: args[1]) else { exit(1) }
let frac = args.count > 2 ? (Double(args[2]) ?? 0.7) : 0.7
let app = NSApplication.shared
app.setActivationPolicy(.regular)
var windows: [NSWindow] = []
for screen in NSScreen.screens {
    let sf = screen.frame
    let win = KeyableWindow(contentRect: sf, styleMask: .borderless,
                            backing: .buffered, defer: false)
    win.isOpaque = false
    win.backgroundColor = .clear
    win.level = .screenSaver
    win.hasShadow = false
    win.ignoresMouseEvents = false
    win.acceptsMouseMovedEvents = true
    win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    let view = OverlayView(image: image, frame: NSRect(origin: .zero, size: sf.size), frac: CGFloat(frac))
    win.contentView = view
    win.makeKeyAndOrderFront(nil)
    win.makeFirstResponder(view)
    windows.append(win)
}
NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { _ in NSApp.terminate(nil); return nil }
app.activate(ignoringOtherApps: true)
windows.first?.makeKeyAndOrderFront(nil)
app.run()
```
