#!/usr/bin/env bash
# Drives the release APK on the emulator: first-run welcome, the Mus'haf,
# chrome, sheets, a recitation, a long-press; a screenshot at each step,
# and the whole logcat. Coordinates are in dp, converted with the
# display's density.
APK=$1
OUT=$2
mkdir -p "$OUT"
PKG=com.mulhimfy.mishkat
adb wait-for-device
adb shell settings put global window_animation_scale 1
read -r W H <<<"$(adb shell wm size | grep -oE '[0-9]+x[0-9]+' | tail -1 | tr x ' ')"
D=$(adb shell wm density | grep -oE '[0-9]+' | tail -1)
echo "screen ${W}x${H} density $D"
px() { echo $(( $1 * D / 160 )); }
tap() { adb shell input tap "$(px "$1")" "$(px "$2")"; sleep "${3:-2}"; }
shot() {
  adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >/dev/null 2>&1 || true
  adb exec-out screencap -p > "$OUT/$1.png"; echo "shot $1"
}
WD=$(( W * 160 / D ))
HD=$(( H * 160 / D ))

# A slow emulator's own apps time out ("Pixel Launcher isn't responding")
# and the dialog swallows every tap: hide those dialogs, let it settle.
adb shell settings put global hide_error_dialogs 1
adb shell input keyevent KEYCODE_HOME
sleep 25
adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >/dev/null 2>&1 || true
adb install -r "$APK" || { echo "install failed"; exit 0; }
adb logcat -c
adb shell am start -W -n $PKG/.MainActivity
sleep 10
shot 01_welcome
# Onboarding: Next, Next, Begin (bottom-right button).
tap $(( WD - 70 )) $(( HD - 62 )) 3
shot 02_light
tap $(( WD - 70 )) $(( HD - 62 )) 3
shot 03_way
tap $(( WD - 70 )) $(( HD - 62 )) 4
shot 04_mushaf
# Turn a page (finger left to right), then back to the opening.
adb shell input swipe "$(px 60)" "$(px $(( HD / 2 )))" "$(px $(( WD - 60 )))" "$(px $(( HD / 2 )))" 300; sleep 3
shot 05_page2
# Chrome.
tap $(( WD / 2 )) $(( HD / 2 )) 3
shot 06_chrome
# Listen sheet (second dock item): shot, then its Play button (bottom).
tap $(( WD * 3 / 8 )) $(( HD - 50 )) 3
shot 07_listen
tap $(( WD / 2 )) $(( HD - 45 )) 14
shot 08_playing
adb shell dumpsys media_session > "$OUT/media_session.txt" 2>&1 || true
sleep 12
shot 09_playing_later
adb shell dumpsys media_session > "$OUT/media_session_later.txt" 2>&1 || true
# Stop (mini player's close), then hold a verse: the lens, the verse bar.
tap $(( WD - 40 )) $(( HD - 50 )) 3
adb shell input swipe "$(px $(( WD / 2 )))" "$(px 330)" "$(px $(( WD / 2 )))" "$(px 330)" 1400; sleep 3
shot 10_verse_bar
adb shell input keyevent KEYCODE_BACK; sleep 2
# Turn the page over (translation on its back): chrome, then the top-right action.
tap $(( WD / 2 )) $(( HD / 2 )) 3
tap $(( WD - 44 )) 64 4
shot 11_flipped
tap $(( WD / 2 )) $(( HD / 2 )) 3
# Look sheet.
tap $(( WD / 2 )) $(( HD / 2 )) 2
tap $(( WD * 5 / 8 )) $(( HD - 50 )) 3
shot 12_look
adb shell input keyevent KEYCODE_BACK; sleep 2
adb shell dumpsys meminfo $PKG | grep -E "TOTAL|Java Heap|Native Heap|Graphics" > "$OUT/meminfo.txt" || true
adb shell dumpsys gfxinfo $PKG > "$OUT/gfxinfo.txt" || true
adb logcat -d > "$OUT/logcat.txt"
grep -E "FATAL EXCEPTION|E/flutter|ANR in" "$OUT/logcat.txt" | head -40 > "$OUT/errors.txt" || true
echo "errors: $(wc -l < "$OUT/errors.txt")"
exit 0
