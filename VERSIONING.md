# Android Jenkins Agent - Versionierung

## Tagging Schema

### Format
```
android-jenkins-agent:MAJOR.MINOR.PATCH-YYYYMMDD
android-jenkins-agent:MAJOR.MINOR.PATCH
android-jenkins-agent:latest
```

### Beispiele
```bash
# Vollständiges Tag mit Datum
android-jenkins-agent:1.0.0-20260310

# Ohne Datum
android-jenkins-agent:1.0.0

# Latest
android-jenkins-agent:latest
```

## Versionierung

| MAJOR | Breaking Changes | Java Version Update, Android SDK Major |
| MINOR | Feature Updates | Neue Tools (ktlint, detekt), Gradle Update |
| PATCH | Bug Fixes | Dockerfile Fixes, Security Updates |

## Version-Datei

Die aktuelle Version steht in `VERSION`:
```
1.0.0
```

## Build Skript

```bash
./build.sh [patch|minor|major]
```

---

*Stand: 2026-03-10*