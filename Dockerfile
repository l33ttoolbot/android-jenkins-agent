# Android Jenkins Build Agent - Complete CI/CD Toolchain
# Java 17 + Android SDK 35 + Quality Tools
# Optimiert für x86_64 Jenkins Pipeline Builds

FROM eclipse-temurin:17-jdk-jammy

# ==================== Version Labels ====================
ARG VERSION=1.0.0
ARG BUILD_DATE
ARG VCS_REF

LABEL org.opencontainers.image.title="Android Jenkins Agent" \
      org.opencontainers.image.description="Android CI/CD Build Agent with Java 17, Gradle 8.7, Android SDK 35, ktlint, detekt, SonarQube" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.source="https://github.com/l33ttoolbot/android-jenkins-agent" \
      org.opencontainers.image.vendor="Beemaster" \
      org.opencontainers.image.licenses="MIT"

# ==================== Build Arguments ====================
ARG ANDROID_COMPILE_SDK=35
ARG ANDROID_BUILD_TOOLS=35.0.0
ARG ANDROID_TARGET_SDK=35
ARG ANDROID_SDK_TOOLS=14742923
ARG KTLINT_VERSION=1.3.1
ARG DETEKT_VERSION=1.23.6
ARG SONAR_VERSION=8.0.1.6346

# Gradle Version matching project
ENV GRADLE_VERSION=8.7

# Environment Variables
ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    ANDROID_COMPILE_SDK=${ANDROID_COMPILE_SDK} \
    ANDROID_BUILD_TOOLS=${ANDROID_BUILD_TOOLS} \
    ANDROID_TARGET_SDK=${ANDROID_TARGET_SDK} \
    DEBIAN_FRONTEND=noninteractive \
    GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.parallel=true -Xmx4g -XX:+HeapDumpOnOutOfMemoryError" \
    JAVA_OPTS="-Xmx4g" \
    PATH="/opt/gradle/gradle-${GRADLE_VERSION}/bin:/opt/sonar-scanner-${SONAR_VERSION}-linux-x64/bin:/root/.local/bin:${PATH}"

# ==================== System Dependencies ====================
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    git-lfs \
    curl \
    wget \
    unzip \
    zip \
    openssh-client \
    gnupg \
    lsb-release \
    python3 \
    python3-pip \
    nodejs \
    npm \
    libc6-i386 \
    lib32stdc++6 \
    lib32z1 \
    lib32ncurses6 \
    lib32gcc-s1 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ==================== Gradle ====================
RUN wget -q "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -O /tmp/gradle.zip && \
    mkdir -p /opt/gradle && \
    unzip -q /tmp/gradle.zip -d /opt/gradle && \
    ln -s /opt/gradle/gradle-${GRADLE_VERSION}/bin/gradle /usr/local/bin/gradle && \
    rm /tmp/gradle.zip && \
    gradle --version

# ==================== Android SDK ====================
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget -q "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS}_latest.zip" -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# Accept Android SDK Licenses
RUN yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --licenses 2>/dev/null || true

# Install Android SDK Components (including lint)
RUN ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --update 2>/dev/null && \
    ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager \
    "platforms;android-${ANDROID_COMPILE_SDK}" \
    "build-tools;${ANDROID_BUILD_TOOLS}" \
    "platform-tools" \
    "extras;android;m2repository" \
    "extras;google;m2repository" \
    "cmdline-tools;latest" 2>/dev/null || true

# ==================== Kotlin Linter: ktlint ====================
RUN wget -q "https://github.com/pinterest/ktlint/releases/download/${KTLINT_VERSION}/ktlint" -O /usr/local/bin/ktlint && \
    chmod +x /usr/local/bin/ktlint && \
    ktlint --version

# ==================== Kotlin Static Analysis: detekt ====================
RUN wget -q "https://github.com/detekt/detekt/releases/download/v${DETEKT_VERSION}/detekt-cli-${DETEKT_VERSION}.zip" -O /tmp/detekt.zip && \
    unzip -q /tmp/detekt.zip -d /opt/detekt && \
    ln -s /opt/detekt/bin/detekt-cli /usr/local/bin/detekt && \
    rm /tmp/detekt.zip && \
    detekt --version || true

# ==================== SonarQube Scanner ====================
RUN wget -q "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_VERSION}-linux-x64.zip" -O /tmp/sonar.zip && \
    unzip -q /tmp/sonar.zip -d /opt && \
    ln -s /opt/sonar-scanner-${SONAR_VERSION}-linux-x64/bin/sonar-scanner /usr/local/bin/sonar-scanner && \
    rm /tmp/sonar.zip && \
    sonar-scanner --version || echo "SonarScanner installed"

# ==================== OWASP Dependency Check ====================
RUN mkdir -p /opt/dependency-check && \
    wget -q "https://github.com/jeremylong/DependencyCheck/releases/download/v9.1.0/dependency-check-9.1.0-release.zip" -O /tmp/depcheck.zip && \
    unzip -q /tmp/depcheck.zip -d /opt && \
    mv /opt/dependency-check /opt/dependency-check-core && \
    ln -s /opt/dependency-check-core/bin/dependency-check.sh /usr/local/bin/dependency-check || \
    echo "dependency-check wird via Gradle Plugin ausgeführt" && \
    rm -tmp/depcheck.zip 2>/dev/null || true

# ==================== GitLeaks (Secrets Scanner) ====================
RUN wget -q "https://github.com/gitleaks/gitleaks/releases/download/v8.18.2/gitleaks_8.18.2_linux_x64.tar.gz" -O /tmp/gitleaks.tar.gz && \
    tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/gitleaks && \
    rm /tmp/gitleaks.tar.gz && \
    gitleaks version

# ==================== Danger (Code Review Automation) ====================
RUN npm install -g danger && \
    danger --version || echo "Danger installiert"

# ==================== Android Lint (via SDK) ====================
# Android Lint ist bereits im SDK enthalten
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/build-tools/${ANDROID_BUILD_TOOLS}"

# ==================== SSH Known Hosts ====================
RUN mkdir -p /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts && \
    ssh-keyscan gitlab.com >> /root/.ssh/known_hosts && \
    ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts && \
    chmod 700 /root/.ssh && \
    chmod 644 /root/.ssh/known_hosts

# ==================== Gradle Cache Permissions ====================
RUN mkdir -p /root/.gradle /root/.android && \
    chmod -R 777 /root/.gradle /root/.android

# Working Directory
WORKDIR /workspace

# Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD java -version 2>&1 | grep -q "17" && gradle --version >/dev/null 2>&1

# Default Command - Keep container running for Jenkins Agent
# Use: docker run -d android-jenkins-agent (for Jenkins JNLP agent)
# Or: docker run -it android-jenkins-agent /bin/bash (for interactive)
CMD ["tail", "-f", "/dev/null"]