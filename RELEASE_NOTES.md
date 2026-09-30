Pixel-style eye break reminder for the macOS menu bar: a 20-second 20-20-20 break every 20 min and a ~4 min eye yoga routine every hour. Both intervals can be changed in the menu.

Runs on macOS 14+ (Apple Silicon and Intel).

## Install
1. Download **EyeYoga-*.zip** below and double-click it to unzip.
2. Move **EyeYoga.app** into your **Applications** folder.
3. Open it. The app isn't notarized by Apple, so macOS blocks the first launch:
   - Go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway** next to "EyeYoga".
   - Or run this once in Terminal: `xattr -dr com.apple.quarantine /Applications/EyeYoga.app`
4. Look for the eye in the menu bar. There is no Dock icon.

## Start at login
**System Settings → General → Login Items & Extensions**, click **+** under "Open at Login" and pick EyeYoga.

## Remove
Quit it from the eye menu, remove it from Login Items, and delete the app.
