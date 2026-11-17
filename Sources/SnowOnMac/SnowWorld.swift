import Cocoa
import CoreGraphics

struct Ledge {
    let id: Int
    var rect: CGRect
    var depth: [CGFloat]
    init(id: Int, rect: CGRect) {
        self.id = id; self.rect = rect
        depth = Array(repeating: 0, count: max(1, Int(ceil(rect.width / 8))))
    }
    func index(_ x: CGFloat) -> Int { max(0, min(depth.count - 1, Int((x - rect.minX) / 8))) }
}
struct Flake {
    var p: CGPoint
    var v: CGVector
    var r: CGFloat
}
enum BallSupport {
    case ledge(Int)
    case ball(UUID)
}
struct Ball {
    let id = UUID()
    var support: BallSupport? = nil
    var p: CGPoint
    var v = CGVector.zero
    var r: CGFloat = 10
}
final class SnowWorld {
    var size: CGSize
    var flakes: [Flake] = []
    var ledges: [Int: Ledge] = [:]
    var balls: [Ball] = []
    var selected: Int?
    var lastPointer = CGPoint.zero
    var spawnBudget: CGFloat = 0
    init(size: CGSize) { self.size = size; reset() }
    func reset() {
        flakes.removeAll(); balls.removeAll(); selected = nil
        ledges = [-1: Ledge(id: -1, rect: CGRect(x: 0, y: 12, width: size.width, height: 0))]
    }
    func sync(_ incoming: [Int: CGRect]) {
        for id in Array(ledges.keys) where id != -1 {
            guard let old = ledges[id] else { continue }
            if let rect = incoming[id], abs(rect.minX - old.rect.minX) < 2,
               abs(rect.minY - old.rect.minY) < 2, abs(rect.width - old.rect.width) < 2 { continue }
            for (i, d) in old.depth.enumerated() where d > 0 {
                for _ in 0..<min(12, max(1, Int(d / 2))) {
                    guard flakes.count < 1100 else { break }
                    flakes.append(Flake(p: CGPoint(x: old.rect.minX + CGFloat(i) * 8 + 4,
                                                   y: old.rect.minY + CGFloat.random(in: 0...d)),
                                        v: CGVector(dx: .random(in: -35...35), dy: -45), r: 2.3))
                }
            }
            for i in balls.indices {
                if case .ledge(let supportID)? = balls[i].support, supportID == id { balls[i].support = nil }
            }
            ledges.removeValue(forKey: id)
        }
        for (id, rect) in incoming where ledges[id] == nil { ledges[id] = Ledge(id: id, rect: rect) }
    }
    func step(_ dt: CGFloat, intensity: CGFloat) {
        spawnBudget += dt * intensity
        while spawnBudget >= 1 {
            spawnBudget -= 1
            if flakes.count < 1100 {
                flakes.append(Flake(p: CGPoint(x: .random(in: 0...max(1, size.width)), y: size.height + 5),
                                    v: CGVector(dx: .random(in: -12...12), dy: -.random(in: 24...70)), r: .random(in: 1.1...2.8)))
            }
        }
        let ordered = ledges.keys.sorted { ledges[$0]!.rect.minY > ledges[$1]!.rect.minY }
        var survivors: [Flake] = []
        for var f in flakes {
            let before = f.p
            f.v.dy = max(-160, f.v.dy - dt * 9)
            f.p.x += f.v.dx * dt; f.p.y += f.v.dy * dt
            var landed = false
            for id in ordered {
                guard var l = ledges[id], f.p.x >= l.rect.minX, f.p.x <= l.rect.maxX else { continue }
                let j = l.index(f.p.x), top = l.rect.minY + l.depth[l.index(f.p.x)]
                if before.y >= top && f.p.y <= top {
                    let cap: CGFloat = id == -1 ? 65 : 24
                    l.depth[j] = min(cap, l.depth[j] + 0.9)
                    if j > 0 { l.depth[j - 1] = min(cap, l.depth[j - 1] + 0.25) }
                    if j + 1 < l.depth.count { l.depth[j + 1] = min(cap, l.depth[j + 1] + 0.25) }
                    ledges[id] = l; landed = true; break
                }
            }
            if !landed && f.p.y > -10 && f.p.x > -50 && f.p.x < size.width + 50 { survivors.append(f) }
        }
        flakes = survivors
        updateBalls(dt)
    }
    func surfaceHeight(_ ledge: Ledge, x: CGFloat) -> CGFloat {
        ledge.rect.minY + ledge.depth[ledge.index(x)]
    }
    func isResting(_ i: Int, visited: Set<UUID> = []) -> Bool {
        guard i != selected, !visited.contains(balls[i].id) else { return false }
        var seen = visited; seen.insert(balls[i].id)
        switch balls[i].support {
        case .ledge(let id):
            guard let l = ledges[id] else { return false }
            return balls[i].p.x >= l.rect.minX && balls[i].p.x <= l.rect.maxX
        case .ball(let id):
            guard let j = balls.firstIndex(where: { $0.id == id }) else { return false }
            return isResting(j, visited: seen)
        case nil: return false
        }
    }
    // Resolve supports from the bottom upward, independent of creation order.
    func resolve(_ i: Int, visited: Set<UUID> = []) {
        guard i != selected, !visited.contains(balls[i].id) else { return }
        var seen = visited; seen.insert(balls[i].id)
        switch balls[i].support {
        case .ledge(let id):
            guard let l = ledges[id], balls[i].p.x >= l.rect.minX, balls[i].p.x <= l.rect.maxX else {
                balls[i].support = nil; return
            }
            balls[i].p.y = surfaceHeight(l, x: balls[i].p.x) + balls[i].r
            balls[i].v = .zero
        case .ball(let id):
            guard let j = balls.firstIndex(where: { $0.id == id }), isResting(j, visited: seen) else {
                balls[i].support = nil; return
            }
            resolve(j, visited: seen)
            balls[i].p = CGPoint(x: balls[j].p.x, y: balls[j].p.y + balls[j].r + balls[i].r - 1)
            balls[i].v = .zero
        case nil: break
        }
    }
    func updateBalls(_ dt: CGFloat) {
        for i in balls.indices { resolve(i) }
        for i in balls.indices.sorted(by: { balls[$0].p.y < balls[$1].p.y }) where i != selected {
            if isResting(i) { resolve(i); continue }
            let before = balls[i].p
            balls[i].v.dy -= 260 * dt
            balls[i].p.x += balls[i].v.dx * dt; balls[i].p.y += balls[i].v.dy * dt
            balls[i].p.x = min(size.width - balls[i].r, max(balls[i].r, balls[i].p.x))
            guard balls[i].v.dy <= 0 else { continue }
            var height: CGFloat = -.greatestFiniteMagnitude
            var support: BallSupport?
            var snapX = balls[i].p.x
            for (id, l) in ledges where balls[i].p.x >= l.rect.minX && balls[i].p.x <= l.rect.maxX {
                let y = surfaceHeight(l, x: balls[i].p.x) + balls[i].r
                if (before.y >= y - 2 || id == -1) && balls[i].p.y <= y && y > height {
                    height = y; support = .ledge(id); snapX = balls[i].p.x
                }
            }
            for j in balls.indices where j != i && isResting(j) {
                let occupied = balls.indices.contains { k in
                    if k != i, case .ball(let id)? = balls[k].support { return id == balls[j].id }
                    return false
                }
                if occupied { continue }
                let y = balls[j].p.y + balls[j].r + balls[i].r - 1
                if abs(balls[i].p.x - balls[j].p.x) <= max(10, balls[j].r * 0.8),
                   before.y >= y - 3, balls[i].p.y <= y, y > height {
                    height = y; support = .ball(balls[j].id); snapX = balls[j].p.x
                }
            }
            if let support = support {
                balls[i].support = support; balls[i].p = CGPoint(x: snapX, y: height); balls[i].v = .zero
            }
        }
    }
    // A little placement assistance makes trackpad stacking forgiving.
    func end() {
        guard let i = selected else { return }
        selected = nil
        let p = balls[i].p
        let candidates = balls.indices.filter { j in
            j != i && isResting(j) &&
            !balls.contains(where: { b in if case .ball(let id)? = b.support { return id == balls[j].id }; return false }) &&
            abs(p.x - balls[j].p.x) <= max(18, balls[j].r) &&
            abs(p.y - (balls[j].p.y + balls[j].r + balls[i].r - 1)) <= 28
        }
        if let j = candidates.min(by: { abs(balls[$0].p.y - p.y) < abs(balls[$1].p.y - p.y) }) {
            balls[i].support = .ball(balls[j].id); resolve(i); return
        }
        let surfaces = ledges.values.filter { l in
            p.x >= l.rect.minX && p.x <= l.rect.maxX &&
            abs(p.y - (surfaceHeight(l, x: p.x) + balls[i].r)) <= 24
        }
        if let l = surfaces.min(by: { abs(surfaceHeight($0, x: p.x) + balls[i].r - p.y) < abs(surfaceHeight($1, x: p.x) + balls[i].r - p.y) }) {
            balls[i].support = .ledge(l.id); resolve(i)
        }
    }
    var snowmen: [[Int]] {
        var result: [[Int]] = []
        for base in balls.indices where isResting(base) {
            guard case .ledge? = balls[base].support else { continue }
            let child: (Int) -> Int? = { parent in
                self.balls.indices.first { i in
                    if case .ball(let id)? = self.balls[i].support { return id == self.balls[parent].id && self.isResting(i) }
                    return false
                }
            }
            if let middle = child(base), let head = child(middle) { result.append([base, middle, head]) }
        }
        return result
    }
    func begin(_ p: CGPoint) {
        selected = balls.indices.reversed().first { hypot(balls[$0].p.x - p.x, balls[$0].p.y - p.y) <= balls[$0].r + 8 }
        if selected == nil {
            let hasSnow = ledges.values.contains { l in
                p.x >= l.rect.minX && p.x <= l.rect.maxX && l.depth[l.index(p.x)] > 1 && abs(p.y - l.rect.minY) < l.depth[l.index(p.x)] + 22
            }
            guard hasSnow else { return }
            if balls.count >= 24 { balls.removeFirst() }
            balls.append(Ball(p: p)); selected = balls.count - 1
        }
        if let i = selected {
            balls[i].support = nil; balls[i].v = .zero
            for j in balls.indices where j != i { if !isResting(j) { balls[j].support = nil } }
        }
        lastPointer = p
    }
    func drag(_ p: CGPoint) {
        guard let i = selected else { return }
        let distance = hypot(p.x - lastPointer.x, p.y - lastPointer.y)
        var gathered: CGFloat = 0
        for id in Array(ledges.keys) {
            guard var l = ledges[id], p.x >= l.rect.minX, p.x <= l.rect.maxX,
                  p.y >= l.rect.minY - balls[i].r && p.y <= surfaceHeight(l, x: p.x) + balls[i].r + 12 else { continue }
            let j = l.index(p.x)
            for k in max(0, j - 2)...min(l.depth.count - 1, j + 2) {
                let take = min(l.depth[k], distance * 0.2); l.depth[k] -= take; gathered += take
            }
            ledges[id] = l
        }
        balls[i].r = min(58, sqrt(balls[i].r * balls[i].r + gathered * 3))
        balls[i].p = p
        balls[i].v = CGVector(dx: min(450, max(-450, (p.x - lastPointer.x) * 18)),
                             dy: min(450, max(-450, (p.y - lastPointer.y) * 18)))
        lastPointer = p
    }
}
