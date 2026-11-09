# Maintenance

`dev-clean` reclaims space from regenerable developer artifacts. It never
touches source, archives, exported IPAs, or user data.

## Install

```sh
~/Documents/Programação/Misc/dotfiles/Maintenance/install.sh
```

This copies the executable to `~/.local/bin/dev-clean` (a plain copy, because
macOS TCC blocks launchd jobs from opening files under `~/Documents`) and loads
`top.abacate.dev-clean`, a weekly launchd job.

## What it deletes

| Group | Default | What |
|-------|---------|------|
| `simulators` | keeps 2 newest iOS minor versions | Old simulator runtimes, their devices, orphaned device folders, unavailable devices |
| `device-support` | keeps 2 newest | Old `iOS DeviceSupport` symbol folders |
| `xcode-derived` | 30 days | `~/Library/Developer/Xcode/DerivedData` entries unused for a month, plus any entry whose `WorkspacePath` no longer exists |
| `ralph` | 14 days | `.ralph-loop/DerivedData` entries and app `build/` intermediates (`.xcarchive` and `export/` are kept) |
| `swift-build` | 30 days | SwiftPM `.build` folders under `~/Documents/Programação` |
| `caches` | 30 days (aged entries) | Homebrew, npm, uv, Periphery, SwiftPM, CoreDevice, and superseded CLI versions |

The weekly launchd job runs `simulators,device-support,xcode-derived,caches`.
macOS blocks launchd jobs from reading `~/Documents`, so run the workspace
groups from a terminal:

```sh
dev-clean --only ralph,swift-build
```

## Usage

```sh
dev-clean --dry-run                       # show what would be deleted
dev-clean                                 # run all default groups
dev-clean --only simulators --dry-run     # one group
dev-clean --only ralph --ralph-days 7     # tighter retention
dev-clean --only caches --cache-days 0    # clear all aged caches now
dev-clean --force                         # allow deleting while Xcode/simulators run
```

Logs: `~/Library/Logs/dev-clean.log`. Uninstall with `./install.sh --uninstall`.

## Safety

- `dev-clean` takes a lock, so overlapping runs exit immediately.
- It skips Xcode DerivedData age-based cleanup while a build is running
  (`xcodebuild`/`XCBBuildService`); orphaned entries are still removed.
- It skips a simulator runtime used by a booted device unless `--force` is set.
- It skips a `.ralph-loop` whose PID file points at a live process.
- It never deletes a `.build` or `build/` entry that contains Git-tracked files.
- `.xcarchive` folders and `build/export/` outputs are never deleted.
- Chrome caches are deliberately excluded; clearing them can drop open tabs and
  profiles. Use Chrome's own settings when you want that.
- If `simctl` reports that it removed a runtime but could not reclaim its
  MobileAsset, run the `sudo rm -rf` command it prints.
