# Architecture

The app runs in the menu bar rather than showing a normal application window. It draws above the existing desktop; it does not edit the wallpaper image.

## Data and rendering

1. `AppDelegate` creates a transparent `SnowPanel` and `SnowView` for each display.
2. A 30 Hz timer calls `SnowWorld.step` and requests a redraw.
3. Every ninth tick, Core Graphics returns on-screen window geometry. Front-to-back window rectangles determine which upper edges are exposed.
4. `SnowWorld.sync` compares those ledges with the previous set. Missing or moved ledges release their stored snow into particles.
5. `SnowView.draw` paints flakes, accumulated piles and shaded balls.

Window coordinates from Core Graphics use a different vertical origin from AppKit. `windowLedges` converts them to global AppKit coordinates and then to panel-local coordinates. This needs manual validation on different multi-display arrangements.

## Simulation

`Ledge` stores surface geometry and an array of snow depths in roughly 8-point bins. Falling flakes cross ledge heights and add to the bins. `SnowWorld` caps depths and particle counts to keep state bounded. The bottom of the display is a persistent ledge with ID -1.

`begin` selects a ball or creates one at a snowy surface. `drag` removes nearby snow and increases the ball’s radius according to the amount collected. On release, nearby placement targets snap into alignment. Otherwise gravity moves the ball until it lands on a window ledge, the ground or another supported ball. Each ball has a stable UUID and an optional ledge/ball support reference. Supports resolve bottom-up, and removal of a supporting window or ball releases its dependents. Three balls in a supported chain are drawn as a snowman.

This is intentionally a simple 2D simulation rather than a full rigid-body physics engine. The fixed time step slows simulation under load instead of catching up with elapsed wall-clock time.

## Input

Normal panels ignore mouse events. Play mode turns mouse handling on, makes a panel key, and gives the view keyboard focus. Escape exits play mode. The menu remains an alternate way to turn play mode off.

## Useful starting changes

| Change | Location |
| --- | --- |
| Snow color, ball shading or play-mode hint | `SnowView.draw` |
| Gravity, limits, accumulation or ball growth | `SnowWorld` |
| Snowfall presets and menu labels | `AppDelegate` |
| Window polling and exposed-edge detection | `AppDelegate.frame` and `windowLedges` |
| App name, version or minimum macOS | `Resources/Info.plist` |

No screenshot pixels are captured or saved. The implementation uses window geometry only. Its behavior under different macOS privacy configurations still needs manual checking.
