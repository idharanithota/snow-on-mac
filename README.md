# SnowOnMac ❄️

An interactive snow overlay for the macOS desktop, built with Swift and AppKit.
Snow falls over your existing wallpaper, gathers on window tops, and drops when windows move or close. Switch to play mode to roll snow into snowballs.

**Status:** first prototype. The app compiles and simulation tests pass. Desktop rendering, controls and resource use still need testing on a real user session; GUI launch was unsuccessful in the development environment. No performance measurements are claimed.

## Features

- Snow accumulates on exposed window tops and along the bottom of the screen.
- Moving, minimizing or closing a window releases its snow.
- Drag through a pile in play mode to grow a snowball; release to throw it.
- Click-through normal mode keeps your apps usable.
- Menu bar controls for intensity, pausing, adding snow, clearing and quitting.
- Separate overlays for connected displays.
- No external dependencies, network requests or account required.

## Requirements

- macOS 13 or later.
- Apple Command Line Tools with Swift 5.8 or later (`xcode-select --install` if missing).
- Developed for an M1 Mac with 8 GB RAM. Scripts compile for the host architecture; Intel behavior is untested.

## Build and run

Open Terminal in this project folder:

```sh
./scripts/test.sh
./scripts/run.sh
```

`run.sh` builds the app and opens it. To build without launching:

```sh
./scripts/build.sh
```

The output is `build/SnowOnMac.app`. You can also double-click `build.command` in Finder to build. The app is locally ad-hoc signed, not Apple notarized.

## Build a snowman (v0.2.0)

1. Quit the old app from its snowflake menu before running the updated build.
2. Choose **Add snow to play with**, then **Play with snow**.
3. Hold and drag in a pile to make a large base ball. Release it on the ground or just above a window’s top edge.
4. Roll a second ball away from the first, then drag it onto the first ball’s top and release. Nearby placements snap into alignment.
5. Make a third ball and place it on top. The supported three-ball stack automatically gets eyes, a carrot nose, buttons, arms, a red scarf and a hat.
6. Press Escape to return to normal desktop interaction.

For the classic shape, roll the base longest, the middle less, and the head least. Any three supported balls trigger the decorations. You can pick up individual balls again. Moving or closing a supporting window releases the stack; it can settle and reform on a lower surface. These are whole app windows, not individual browser tabs.

## Controls

Click **❄** in the menu bar.

| Control | Action |
| --- | --- |
| Play with snow | Capture mouse drags to roll and throw snowballs |
| Escape | Leave play mode and return to normal clicking |
| Add snow to play with | Fill existing surfaces immediately |
| Light snow / Cozy snow | Change the particle spawn rate |
| Pause snowfall | Pause the simulation |
| Clear snow | Remove flakes, piles and balls |
| Quit Snow | Remove the overlay and quit |

To try snowballs immediately: **Add snow to play with → Play with snow**, then drag through the pile at the bottom of the screen. Normal mode passes mouse clicks through. Play mode temporarily captures them.

## Project layout

| Path | Purpose |
| --- | --- |
| `Sources/SnowOnMac/main.swift` | App entry point |
| `Sources/SnowOnMac/AppDelegate.swift` | Menu bar, overlay windows, window tracking and frame timer |
| `Sources/SnowOnMac/SnowWorld.swift` | Snow simulation, accumulation, gravity and snowball interactions |
| `Sources/SnowOnMac/SnowView.swift` | Drawing and mouse/keyboard input |
| `Resources/Info.plist` | macOS app bundle metadata |
| `Tests/main.swift` | Simulation regression checks |
| `scripts/` | Build, run and test commands |
| `docs/ARCHITECTURE.md` | How the app works and what to change |
| `docs/TESTING.md` | Automated checks and desktop testing checklist |
| `docs/GITHUB.md` | Beginner-friendly steps for publishing the repository |
| `.github/workflows/build.yml` | macOS build/test workflow |

## Performance approach

The simulation runs at 30 frames per second, polls window geometry approximately three times per second, and caps active flakes at 1,100 and snowballs at 24 per display. Pile depths are bounded. Actual RAM, CPU and battery usage have not been measured. Start with Light snow on battery.

## Current limitations

- Balls support vertical stacks on the ground and window tops; sideways collisions and rolling physics are simplified.
- Window edges are approximated in short segments, without rounded-corner handling.
- Moving a window releases its snow instead of carrying the pile.
- Changing display layout clears the scene; changing Spaces can release snow.
- No Dock accumulation, snowmen, custom wallpaper or automatic launch at login yet.
- Browser tabs are not tracked independently; the app tracks whole windows.
- Automated tests do not validate graphical rendering or interaction.

## Roadmap

- [ ] Validate window tracking and play mode on an M1 desktop
- [ ] Measure CPU, RAM and battery impact
- [x] Add vertical ball stacking on window tops and the ground; decorate three-ball stacks as snowmen
- [ ] Improve pile smoothing and rounded window edges
- [ ] Add Dock accumulation and saved settings
- [ ] Add a demo video after desktop verification

## Author and licensing

Created as Dharani Thota’s macOS learning project with AI-assisted implementation. No open-source license has been selected yet. Choose a license before inviting reuse; publishing source on GitHub alone does not grant an open-source license.
