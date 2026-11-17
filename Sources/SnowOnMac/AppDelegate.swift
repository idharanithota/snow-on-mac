import Cocoa
import CoreGraphics

final class SnowPanel: NSPanel { override var canBecomeKey: Bool { true } }
final class AppDelegate: NSObject, NSApplicationDelegate {
    var status: NSStatusItem!
    var panels: [SnowPanel] = []
    var timer: Timer?
    var tick = 0
    var paused = false
    var play = false
    var intensity: CGFloat = 30
    var playItem: NSMenuItem!
    var pauseItem: NSMenuItem!
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.title = "❄"
        let menu = NSMenu()
        let title = NSMenuItem(title: "Dharani’s Snow", action: nil, keyEquivalent: ""); menu.addItem(title)
        menu.addItem(.separator())
        playItem = add(menu, "Play with snow", #selector(togglePlay))
        pauseItem = add(menu, "Pause snowfall", #selector(togglePause))
        add(menu, "Light snow · best for battery", #selector(light))
        add(menu, "Cozy snow", #selector(cozy))
        add(menu, "Add snow to play with", #selector(seed))
        add(menu, "Clear snow", #selector(clear))
        menu.addItem(.separator())
        add(menu, "Quit Snow", #selector(quit), "q")
        status.menu = menu
        rebuild()
        NotificationCenter.default.addObserver(self, selector: #selector(rebuild), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in self?.frame() }
        RunLoop.main.add(timer!, forMode: .common)
    }
    @discardableResult func add(_ menu: NSMenu, _ title: String, _ action: Selector, _ key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key); item.target = self; menu.addItem(item); return item
    }
    @objc func rebuild() {
        for p in panels { p.orderOut(nil) }; panels.removeAll()
        for screen in NSScreen.screens {
            let p = SnowPanel(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            p.isOpaque = false; p.backgroundColor = .clear; p.hasShadow = false
            p.level = .floating; p.ignoresMouseEvents = !play
            p.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            p.isReleasedWhenClosed = false
            let view = SnowView(size: screen.frame.size)
            view.exitPlay = { [weak self] in self?.setPlay(false) }
            p.contentView = view; p.orderFrontRegardless(); panels.append(p)
        }
    }
    func windowLedges(for panel: SnowPanel, windows: [[String: Any]]) -> [Int: CGRect] {
        let mainHeight = NSScreen.screens.first?.frame.maxY ?? panel.frame.maxY
        var covers: [CGRect] = []
        var result: [Int: CGRect] = [:]
        for w in windows {
            guard let pid = w[kCGWindowOwnerPID as String] as? Int, pid != Int(getpid()),
                  let layer = w[kCGWindowLayer as String] as? Int, layer == 0,
                  let id = w[kCGWindowNumber as String] as? Int,
                  let raw = w[kCGWindowBounds as String] as? [String: Any],
                  let rect = CGRect(dictionaryRepresentation: raw as CFDictionary), rect.width > 80, rect.height > 45,
                  (w[kCGWindowAlpha as String] as? Double ?? 1) > 0 else { continue }
            let r = CGRect(x: rect.minX, y: mainHeight - rect.maxY, width: rect.width, height: rect.height)
            // Split exposed upper edges into short ledges; front windows hide rear edges.
            let start = max(r.minX, panel.frame.minX), end = min(r.maxX, panel.frame.maxX)
            if end > start && r.maxY > panel.frame.minY && r.maxY < panel.frame.maxY - 24 {
                var x = start
                while x < end {
                    let width = min(16, end - x)
                    let point = CGPoint(x: x + width / 2, y: r.maxY + 1)
                    if !covers.contains(where: { $0.contains(point) }) {
                        let segment = Int((x - r.minX) / 16)
                        result[id * 100000 + segment] = CGRect(x: x - panel.frame.minX, y: r.maxY - panel.frame.minY, width: width, height: 0)
                    }
                    x += 16
                }
            }
            covers.append(r)
        }
        return result
    }
    func frame() {
        guard !paused else { return }
        tick += 1
        if tick % 9 == 0 {
            let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
            for p in panels { (p.contentView as? SnowView)?.world.sync(windowLedges(for: p, windows: windows)) }
        }
        for p in panels {
            guard let view = p.contentView as? SnowView else { continue }
            view.world.step(1 / 30, intensity: intensity); view.needsDisplay = true
        }
    }
    func setPlay(_ enabled: Bool) {
        play = enabled; playItem.state = play ? .on : .off
        for p in panels {
            p.ignoresMouseEvents = !play
            (p.contentView as? SnowView)?.world.selected = nil
            p.contentView?.needsDisplay = true
        }
        if play, let p = panels.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) {
            p.makeKey(); p.makeFirstResponder(p.contentView)
        } else { for p in panels { p.resignKey() } }
    }
    @objc func togglePlay() { setPlay(!play) }
    @objc func togglePause() { paused.toggle(); pauseItem.title = paused ? "Resume snowfall" : "Pause snowfall" }
    @objc func light() { intensity = 15 }
    @objc func cozy() { intensity = 40 }
    @objc func clear() { for p in panels { (p.contentView as? SnowView)?.world.reset(); p.contentView?.needsDisplay = true } }
    @objc func seed() {
        for p in panels {
            guard let view = p.contentView as? SnowView else { continue }
            for id in Array(view.world.ledges.keys) {
                guard var l = view.world.ledges[id] else { continue }
                l.depth = l.depth.indices.map { i in id == -1 ? 22 + 7 * sin(CGFloat(i) * 0.12) : 9 }
                view.world.ledges[id] = l
            }
            view.needsDisplay = true
        }
    }
    @objc func quit() { NSApp.terminate(nil) }
}
