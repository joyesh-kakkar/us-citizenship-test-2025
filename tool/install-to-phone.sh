#!/usr/bin/env bash
#
# Builds a release build and installs it on your iPhone, cable-free.
#
# Run this when:
#   * the app stops opening because the signing profile expired (about once a
#     year — see the expiry it prints at the end), or
#   * you changed the code and want the new version on your phone.
#
# Your progress, favorites and streak live on the phone and survive a
# reinstall, so this is always safe to run.
#
#   ./tool/install-to-phone.sh
#
set -euo pipefail

cd "$(dirname "$0")/.."

say() { printf '\n\033[1m%s\033[0m\n' "$1"; }
fail() { printf '\n\033[31m%s\033[0m\n' "$1" >&2; exit 1; }

say "Looking for your iPhone…"

# Ask Flutter for connected devices and keep the first iOS one. Works for both
# cabled and wireless phones.
device_line="$(flutter devices --machine 2>/dev/null \
  | python3 -c '
import json, sys
try:
    devices = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for d in devices:
    if d.get("targetPlatform", "").startswith("ios") and not d.get("emulator", False):
        print(d["id"] + "\t" + d["name"])
        break
' || true)"

if [ -z "$device_line" ]; then
  fail "No iPhone found.

Check that:
  * the phone is unlocked and on the same Wi-Fi as this Mac (or plugged in),
  * you have tapped Trust on the phone at least once,
  * Xcode > Window > Devices and Simulators shows it.

Then run this again."
fi

# cut splits on tab by default; written this way because the bash that ships
# with macOS is 3.2 and mishandles $'\t' inside a parameter expansion.
device_id="$(printf '%s' "$device_line" | cut -f1)"
device_name="$(printf '%s' "$device_line" | cut -f2)"

# Braced: the ellipsis that follows is multi-byte, and macOS bash 3.2 will
# otherwise read it as part of the variable name.
say "Building a release build for ${device_name}…"
flutter build ios --release

say "Installing…"
flutter install --release -d "$device_id"

# Report how long this install is good for, read from the signing profile that
# Xcode actually used, so the date is real rather than assumed.
profile_dir="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
expiry=""
if [ -d "$profile_dir" ]; then
  for p in "$profile_dir"/*.mobileprovision; do
    [ -e "$p" ] || continue
    plist="$(security cms -D -i "$p" 2>/dev/null || true)"
    case "$plist" in
      *com.maplewood.uscitizenshiptest2025*)
        case "$plist" in *"Team Provisioning Profile"*)
          expiry="$(printf '%s' "$plist" \
            | plutil -extract ExpirationDate raw - 2>/dev/null | cut -dT -f1 || true)"
        esac
        ;;
    esac
  done
fi

say "Done — US Citizenship Test 2025 is on $device_name."
echo "Open it from the home screen. No cable, no Mac, works offline."
if [ -n "$expiry" ]; then
  echo "This install is signed until $expiry. Re-run this script on or before then."
fi
