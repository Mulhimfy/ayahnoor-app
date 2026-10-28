# mishkat-ci

Build runner for **Mishkat** (`com.mulhimfy.mishkat`), a Quran Mus'haf app.

This repository holds workflows only. A run checks out the private app
repository with a read-only deploy key, analyses and tests it, builds the
signed release APK, optionally drives it on an Android emulator, and
uploads everything it made as **one sealed file** (AES-256, key held by the
owner). Nothing readable leaves the runner: no source, no build, no log.

```sh
gh workflow run build.yml -R Mulhimfy/mishkat-ci -f ref=main -f smoke=true
```
