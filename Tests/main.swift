import Cocoa

func selfTest() {
    let world = SnowWorld(size: CGSize(width: 800, height: 600))
    world.sync([1: CGRect(x: 100, y: 300, width: 200, height: 0)])
    world.flakes = [Flake(p: CGPoint(x: 140, y: 301), v: CGVector(dx: 0, dy: -60), r: 2)]
    world.step(0.1, intensity: 0)
    assert(world.ledges[1]!.depth.contains(where: { $0 > 0 }), "Snow must land on window")
    world.sync([:]); assert(world.ledges[1] == nil && !world.flakes.isEmpty, "Closing must drop snow")
    world.ledges[-1]!.depth = Array(repeating: 25, count: world.ledges[-1]!.depth.count)
    world.begin(CGPoint(x: 100, y: 25)); world.drag(CGPoint(x: 150, y: 25))
    assert(world.balls.count == 1 && world.balls[0].r > 10, "Rolling must grow snowball")
    world.selected = nil
    for _ in 0..<300 { world.step(1 / 30, intensity: 40) }
    assert(world.flakes.count <= 1100 && world.balls[0].p.y >= 12, "Simulation remains bounded")
    world.reset(); assert(world.balls.isEmpty && world.flakes.isEmpty && world.ledges.count == 1)
    print("PASS: window accumulation, closing releases snow, snowball growth, bounds, reset")
}

selfTest()

func stackingTests() {
    let w = SnowWorld(size: CGSize(width: 800, height: 600))
    let window = CGRect(x: 100, y: 300, width: 300, height: 0)
    w.sync([7: window])
    w.balls = [Ball(p: CGPoint(x: 200, y: 360), r: 24)]
    for _ in 0..<90 { w.step(1/30, intensity: 0) }
    assert(abs(w.balls[0].p.y - 324) < 0.1, "Base must land on the window")
    w.balls.append(Ball(p: CGPoint(x: 205, y: 369), r: 18))
    w.selected = 1; w.end()
    w.balls.append(Ball(p: CGPoint(x: 198, y: 399), r: 13))
    w.selected = 2; w.end()
    assert(w.snowmen.count == 1, "Three placed balls must form a snowman")
    for _ in 0..<300 { w.step(1/30, intensity: 0) }
    assert(w.snowmen.count == 1 && w.balls.allSatisfy { abs($0.p.x - 200) < 0.1 }, "Stack must remain aligned and stable")
    w.begin(w.balls[1].p)
    assert(w.snowmen.isEmpty && !w.isResting(2), "Picking up the middle releases the head")
    w.end()
    for _ in 0..<30 { w.step(1/30, intensity: 0) }
    assert(w.snowmen.count == 1, "Replacing the middle permits the stack to reform")
    w.sync([7: CGRect(x: 100, y: 200, width: 300, height: 0)])
    w.step(1/30, intensity: 0)
    assert(w.snowmen.isEmpty && w.balls[0].p.y < 324, "Moving the window releases the stack")
    w.sync([:])
    for _ in 0..<300 { w.step(1/30, intensity: 0) }
    assert(w.snowmen.count == 1 && abs(w.balls[0].p.y - 36) < 0.1, "Falling balls can restack on the desktop")
    let floorWorld = SnowWorld(size: CGSize(width: 800, height: 600))
    floorWorld.balls = [Ball(p: CGPoint(x: 150, y: 60), r: 20), Ball(p: CGPoint(x: 150, y: 130), r: 15), Ball(p: CGPoint(x: 150, y: 200), r: 10)]
    for _ in 0..<300 { floorWorld.step(1/30, intensity: 0) }
    assert(floorWorld.snowmen.count == 1, "Falling balls stack without manual snapping")
    floorWorld.begin(floorWorld.balls[0].p)
    assert(floorWorld.snowmen.isEmpty && !floorWorld.isResting(1), "Picking up the base releases its stack")
    floorWorld.reset()
    assert(floorWorld.snowmen.isEmpty, "Clear removes snowmen")
    print("PASS: window landing, three-ball snowman, stable stacking, middle/base removal, moving/closing window, gravity stacking, clear")
}
stackingTests()
