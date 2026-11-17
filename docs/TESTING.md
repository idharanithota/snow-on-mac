# Testing

Run `./scripts/test.sh`. It compiles the simulation with `-Onone`, so assertions remain enabled. Failures exit with a nonzero status.

Current checks cover a falling flake landing on a window, a disappearing window releasing its pile, snowball growth from collected snow, bounded simulation state and clearing. The app build is checked separately with `./scripts/build.sh`.

The GitHub Actions workflow runs both commands on macOS. It has not yet run on GitHub; a successful local build does not imply a successful hosted workflow.

## Desktop acceptance checklist

- [ ] Launch the app and find the snowflake menu.
- [ ] Confirm other apps remain clickable in normal mode.
- [ ] Add snow and confirm it appears on visible window tops.
- [ ] Close, minimize, move and resize a window; watch the snow drop.
- [ ] Overlap two windows; check rear edges are hidden.
- [ ] Enter play mode and drag through the bottom pile; confirm ball growth.
- [ ] Throw a ball, press Escape, and confirm normal clicking returns.
- [ ] Check menu exit from play mode as an alternate escape route.
- [ ] Verify pause, clear, intensity and quit controls.
- [ ] Try multiple displays, Spaces and full-screen apps.
- [ ] Inspect Activity Monitor after five minutes of Light snow and Cozy snow.

Record actual macOS version, hardware, display setup and results when reporting problems. Graphical launch failed in the build environment, so these checks remain outstanding.

## Stacking regression checks (v0.2.0)

Automated tests cover landing on a window, snapping three balls into a snowman, stability over 300 frames, removing/replacing the middle, picking up the base, moving/closing the supporting window, falling stacks reassembling on the desktop, gravity-only stacking and clearing snowmen.

Desktop follow-up: check trackpad placement, snowman appearance and window-top alignment. The user’s earlier screenshot confirms snowfall renders on their desktop; the new stacking interaction has not yet been visually verified there.
