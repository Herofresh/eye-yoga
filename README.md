# Eye Yoga

A tiny pixel-style macOS menu bar app that reminds you to rest your eyes.

Breaks follow the AOA [20-20-20 rule](https://www.aoa.org/AOA/Images/Patients/Eye%20Conditions/20-20-20-rule.pdf)
(every 20 minutes, look at something 20 feet away for 20 seconds) plus a longer routine every hour:

- **Every 20 min: micro break, 20 s.** Look out the window at something at least 6 m (20 ft)
  away and blink slowly 10 times.
- **Every 60 min: full eye yoga routine, ~4 min.** It takes the place of the micro break that
  falls on the hour, so you get micro, micro, full, and so on.

The full routine, done seated next to a window, with animated pixel eyes:

| # | Move | Time |
|---|------|------|
| 1 | Palming | 30 s |
| 2 | Blinking | 20 s |
| 3 | Near / far focus, 10 switches | 60 s |
| 4 | Eye rolls, 5 each way | 40 s |
| 5 | Figure-8, 8 loops | 30 s |
| 6 | Up/down, side-to-side | 30 s |
| 7 | Window gaze | 30 s |

Pick **START** (Return), **SNOOZE 5M** or **SKIP** (Esc). Skipping moves on to the next
slot as if the break were done. Finishing a break earns **+1 XP**.

The menu bar shows the countdown (`18:02`). From its menu you can start a full routine or a
micro break now, pause, set the micro interval (15/20/30 min or **Custom…**) and the full
interval (45/60/90 min or **Custom…**, any value from 1 to 240 min), and toggle sound.
Intervals are saved and survive restarts. Locking the screen or sleeping pauses the countdown and
restarts it when you come back. Being idle for 5 minutes counts as a rest and restarts it too.

## Download

Grab the latest **EyeYoga-*.zip** from [Releases](https://github.com/Herofresh/eye-yoga/releases/latest);
the release notes explain installing and starting at login.

## Requirements

macOS 14+ and the Swift toolchain from the Command Line Tools (`xcode-select --install`).
Xcode is not needed.

## Build, install, uninstall

```sh
scripts/build-app.sh   # builds build/EyeYoga.app (ad-hoc signed)
scripts/install.sh     # builds, copies to ~/Applications, starts at login via a LaunchAgent
scripts/uninstall.sh   # stops it and removes the app and LaunchAgent
```

The LaunchAgent is `~/Library/LaunchAgents/at.herofresh.eyeyoga.plist`. Settings and XP
live in UserDefaults (`defaults read at.herofresh.eyeyoga`).

## Development

```sh
swift test                                   # scheduler, routine and frame tests
swift run EyeYoga --interval-seconds 30      # micro break every 30 s, full routine every 90 s
```

`--idle-seconds N` shortens the idle reset the same way. Both flags accept at least 5.

## Releasing

Bump `VERSION`, commit, then run `scripts/release.sh`. It tests, builds a universal app,
zips it, tags `v<VERSION>` and publishes the GitHub release with `RELEASE_NOTES.md`
(needs `gh` logged in as the repo owner).

## Font

[Press Start 2P](https://fonts.google.com/specimen/Press+Start+2P) by CodeMan38, under
the SIL Open Font License 1.1 (`Resources/OFL.txt`).
