import Cocoa

final class SnowView: NSView {
    let world: SnowWorld
    var exitPlay: (() -> Void)?
    init(size: CGSize) { world = SnowWorld(size: size); super.init(frame: CGRect(origin: .zero, size: size)) }
    required init?(coder: NSCoder) { fatalError() }
    override var acceptsFirstResponder: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill(); bounds.fill(using: .copy)
        for l in world.ledges.values {
            let path = NSBezierPath()
            path.move(to: CGPoint(x: l.rect.minX, y: l.rect.minY))
            for (i, d) in l.depth.enumerated() {
                path.line(to: CGPoint(x: min(l.rect.maxX, l.rect.minX + CGFloat(i) * 8 + 4), y: l.rect.minY + d))
            }
            path.line(to: CGPoint(x: l.rect.maxX, y: l.rect.minY)); path.close()
            NSColor(calibratedRed: 0.91, green: 0.96, blue: 1, alpha: 0.97).setFill(); path.fill()
        }
        for f in world.flakes {
            NSColor.white.withAlphaComponent(min(0.95, 0.4 + f.r / 5)).setFill()
            NSBezierPath(ovalIn: CGRect(x: f.p.x - f.r, y: f.p.y - f.r, width: f.r * 2, height: f.r * 2)).fill()
        }
        for b in world.balls {
            let path = NSBezierPath(ovalIn: CGRect(x: b.p.x - b.r, y: b.p.y - b.r, width: b.r * 2, height: b.r * 2))
            NSGradient(starting: .white, ending: NSColor(calibratedRed: 0.64, green: 0.79, blue: 0.91, alpha: 1))?.draw(in: path, angle: -65)
        }
        for stack in world.snowmen { drawSnowman(stack) }
        if window?.ignoresMouseEvents == false {
            let text = "PLAY WITH SNOW  ·  Roll snow · Stack 3 balls on the ground or a window  ·  Esc to return to work"
            let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 13, weight: .medium), .foregroundColor: NSColor.white]
            let width = (text as NSString).size(withAttributes: attrs).width + 32
            let box = CGRect(x: (bounds.width - width) / 2, y: bounds.height - 90, width: width, height: 38)
            NSColor.black.withAlphaComponent(0.75).setFill(); NSBezierPath(roundedRect: box, xRadius: 19, yRadius: 19).fill()
            (text as NSString).draw(at: CGPoint(x: box.minX + 16, y: box.minY + 11), withAttributes: attrs)
        }
    }
    func drawSnowman(_ stack: [Int]) {
        let body = world.balls[stack[1]], head = world.balls[stack[2]]
        func dot(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ color: NSColor) {
            color.setFill(); NSBezierPath(ovalIn: CGRect(x: x-r, y: y-r, width: r*2, height: r*2)).fill()
        }
        let h = head.r, x = head.p.x, y = head.p.y
        // Coal eyes, carrot nose, and a dotted smile.
        dot(x-h*0.3, y+h*0.16, max(1.3,h*0.075), .black)
        dot(x+h*0.3, y+h*0.16, max(1.3,h*0.075), .black)
        let nose = NSBezierPath(); nose.move(to: CGPoint(x:x-1,y:y)); nose.line(to: CGPoint(x:x+h*0.65,y:y-h*0.1)); nose.line(to: CGPoint(x:x-1,y:y-h*0.2)); nose.close()
        NSColor.systemOrange.setFill(); nose.fill()
        for k in -2...2 { dot(x+CGFloat(k)*h*0.16,y-h*0.38+CGFloat(k*k)*h*0.025,max(1,h*0.045),.black) }
        // Red scarf and a Santa-style hat, drawn in screen points.
        NSColor.systemRed.setFill()
        NSBezierPath(roundedRect: CGRect(x:x-h*0.78,y:y-h*0.94,width:h*1.56,height:max(4,h*0.25)),xRadius:3,yRadius:3).fill()
        NSBezierPath(roundedRect: CGRect(x:x+h*0.3,y:y-h*1.65,width:max(4,h*0.25),height:h*0.85),xRadius:2,yRadius:2).fill()
        let hat = NSBezierPath(); hat.move(to: CGPoint(x:x-h*0.85,y:y+h*0.65)); hat.line(to: CGPoint(x:x+h*0.8,y:y+h*0.65)); hat.curve(to: CGPoint(x:x+h*0.35,y:y+h*1.7),controlPoint1:CGPoint(x:x+h*0.7,y:y+h*1.5),controlPoint2:CGPoint(x:x+h*0.3,y:y+h*1.9)); hat.close(); hat.fill()
        NSColor.white.setFill(); NSBezierPath(roundedRect:CGRect(x:x-h*0.9,y:y+h*0.6,width:h*1.8,height:max(4,h*0.25)),xRadius:3,yRadius:3).fill()
        dot(x+h*0.35,y+h*1.7,max(3,h*0.22),.white)
        for offset: CGFloat in [-0.4,0,0.4] { dot(body.p.x,body.p.y+body.r*offset,max(1.5,body.r*0.07),.darkGray) }
        let arms = NSBezierPath(); arms.lineWidth = max(2,body.r*0.07)
        for side: CGFloat in [-1,1] {
            arms.move(to: CGPoint(x:body.p.x+side*body.r*0.85,y:body.p.y))
            arms.line(to: CGPoint(x:body.p.x+side*body.r*1.8,y:body.p.y+body.r*0.55))
        }
        NSColor.brown.setStroke(); arms.stroke()
    }
    override func mouseDown(with event: NSEvent) { world.begin(convert(event.locationInWindow, from: nil)) }
    override func mouseDragged(with event: NSEvent) { world.drag(convert(event.locationInWindow, from: nil)) }
    override func mouseUp(with event: NSEvent) { world.end() }
    override func keyDown(with event: NSEvent) { if event.keyCode == 53 { exitPlay?() } }
}
