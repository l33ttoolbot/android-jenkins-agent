# Android Jenkins Agent - Build Anleitung

## Repository

```
https://github.com/l33ttoolbot/android-jenkins-agent
```

## Auf x86_64 Host bauen

### 1. Repository klonen

```bash
git clone https://github.com/l33ttoolbot/android-jenkins-agent.git
cd android-jenkins-agent
```

### 2. Image bauen

```bash
# Mit Version Tag
./build.sh

# Oder manuell:
VERSION=$(cat VERSION)
DATE=$(date +%Y%m%d)

docker build \
  -t android-jenkins-agent:${VERSION}-${DATE} \
  -t android-jenkins-agent:${VERSION} \
  -t android-jenkins-agent:latest \
  --build-arg VERSION=${VERSION} \
  --build-arg BUILD_DATE=$(date +%Y-%m-%d) \
  --build-arg VCS_REF=$(git rev-parse --short HEAD) \
  .
```

### 3. Testen

```bash
# Java Version
docker run --rm android-jenkins-agent:latest java -version

# Gradle Version
docker run --rm android-jenkins-agent:latest gradle --version

# Android SDK
docker run --rm android-jenkins-agent:latest ls /opt/android-sdk

# ktlint
docker run --rm android-jenkins-agent:latest ktlint --version

# detekt
docker run --rm android-jenkins-agent:latest detekt --version
```

### 4. Für Jenkins Agent verwenden

```bash
# Image taggen für Jenkins
docker tag android-jenkins-agent:latest jenkins-agent:latest
```

---

## Enthaltene Tools

| Tool | Version | Zweck |
|------|---------|-------|
| Java | 17 | JVM |
| Gradle | 8.7 | Build System |
| Android SDK | 35 | Android Platform |
| ktlint | 1.3.1 | Kotlin Linter |
| detekt | 1.23.6 | Static Analysis |
| SonarQube Scanner | 8.0.1 | Code Quality |
| GitLeaks | 8.18 | Secrets Scanner |

---

## Build Timestamp

**Version:** 1.0.0
**Build Date:** 2026-03-10
**Commits seit letztem Build:** 0

```
295c373 feat: add versioning and build script with Docker tags
e7630f3 fix: update SonarQube Scanner to version 8.0.1.6346
bf4df04 fix: remove redundant mv command in Gradle install
```

---

## Schnellstart

```bash
# Ein Command
git clone https://github.com/l33ttoolbot/android-jenkins-agent.git && \
cd android-jenkins-agent && \
./build.sh
```