# Android Jenkins Agent

Docker Image für Jenkins Pipeline Builds mit Android SDK und Java 17.

## Features

- ✅ Java 17 (Eclipse Temurin)
- ✅ Android SDK 35
- ✅ Android Build Tools 35.0.0
- ✅ Git + Git LFS
- ✅ GitHub/GitLab SSH Known Hosts pre-configured
- ✅ Optimiert für x86_64 Build-Hosts

## Build

```bash
docker build -t android-jenkins-agent:latest .
```

## Usage in Jenkins Pipeline

```groovy
pipeline {
    agent {
        docker {
            image 'android-jenkins-agent:latest'
            args '-v $HOME/.gradle:/root/.gradle'
            reuse true
        }
    }
    
    stages {
        stage('Build') {
            steps {
                sh './gradlew assembleDebug'
            }
        }
    }
}
```

## Usage with Jenkins Agent Node

Für x86_64 Build-Hosts:

```bash
# Auf x86_64 Host:
docker run -d \
  --name android-agent \
  -e JENKINS_URL=http://jenkins-master:8080 \
  -e JENKINS_SECRET=<agent-secret> \
  -e JENKINS_AGENT_NAME=android-x86 \
  android-jenkins-agent:latest \
  java -jar /var/jenkins/remoting.jar
```

## Image Size

- ~4.5 GB (mit Android SDK)
- ~1.2 GB (compressed)

## Architecture

- **Target:** linux/amd64 (x86_64)
- **Base:** eclipse-temurin:17-jdk-jammy

## Environment Variables

| Variable | Value |
|----------|-------|
| `ANDROID_HOME` | /opt/android-sdk |
| `ANDROID_SDK_ROOT` | /opt/android-sdk |
| `JAVA_HOME` | /opt/java/openjdk |
| `GRADLE_OPTS` | -Dorg.gradle.daemon=false |

## Pre-installed SDK Components

- `platforms;android-35`
- `build-tools;35.0.0`
- `platform-tools`
- `extras;android;m2repository`
- `extras;google;m2repository`

## GitHub Actions Build

Automatisch beim Push gebaut und zu GitHub Container Registry gepusht.

```yaml
ghcr.io/l33ttoolbot/android-jenkins-agent:latest
```