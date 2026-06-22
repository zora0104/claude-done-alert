import Cocoa

// 全屏拦截式图片提醒：弹出时整屏被透明层盖住，图居中显示。
// 期间任何按键/点击都只用来「关闭提示」，不会操作到电脑；关闭后控制权立即恢复。
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
        // 全屏透明背景；图按高度比例居中绘制（保持比例）
        let isz = img.size
        guard isz.height > 0 else { return }
        let h = bounds.height * frac
        let scale = h / isz.height
        let w = isz.width * scale
        let x = (bounds.width - w) / 2
        let y = (bounds.height - h) / 2
        img.draw(in: NSRect(x: x, y: y, width: w, height: h))
    }
    // 任意点击 / 任意按键 都只用来关闭，事件被本层吞掉，不会传给其他 App
    override func mouseDown(with event: NSEvent) { NSApp.terminate(nil) }
    override func rightMouseDown(with event: NSEvent) { NSApp.terminate(nil) }
    override func keyDown(with event: NSEvent) { NSApp.terminate(nil) }
}

let args = CommandLine.arguments
guard args.count > 1, let image = NSImage(contentsOfFile: args[1]) else { exit(1) }
let frac = args.count > 2 ? (Double(args[2]) ?? 0.7) : 0.7

let app = NSApplication.shared
app.setActivationPolicy(.regular)   // 抢到前台焦点，键盘事件才会进到本层被吞掉

var windows: [NSWindow] = []
for screen in NSScreen.screens {
    let sf = screen.frame   // 整块屏幕
    let win = KeyableWindow(contentRect: sf, styleMask: .borderless,
                            backing: .buffered, defer: false)
    win.isOpaque = false
    win.backgroundColor = .clear      // 透明：看得到底下，但点击被本层拦截
    win.level = .screenSaver
    win.hasShadow = false
    win.ignoresMouseEvents = false    // 关键：拦截鼠标，图外点击也只关提示
    win.acceptsMouseMovedEvents = true
    win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    let view = OverlayView(image: image, frame: NSRect(origin: .zero, size: sf.size), frac: CGFloat(frac))
    win.contentView = view
    win.makeKeyAndOrderFront(nil)
    win.makeFirstResponder(view)
    windows.append(win)
}

// 兜底：任何按键都关闭，并把事件吞掉（return nil），不漏给其他 App
NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { _ in
    NSApp.terminate(nil); return nil
}

app.activate(ignoringOtherApps: true)
windows.first?.makeKeyAndOrderFront(nil)
app.run()
