# Android Jenkins Build Agent
# Optimiert für Jenkins Pipeline Builds auf x86_64
# Java 17 + Android SDK 35

FROM eclipse-temurin:17-jdk-jammy

# Build Arguments
ARG ANDROID_COMPILE_SDK=35
ARG ANDROID_BUILD_TOOLS=35.0.0
ARG ANDROID_TARGET_SDK=35
ARG ANDROID_SDK_TOOLS=14742923

# Environment Variables
ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    ANDROID_COMPILE_SDK=${ANDROID_COMPILE_SDK} \
    ANDROID_BUILD_TOOLS=${ANDROID_BUILD_TOOLS} \
    ANDROID_TARGET_SDK=${ANDROID_TARGET_SDK} \
    DEBIAN_FRONTEND=noninteractive \
    GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.parallel=true -Xmx4g"

# Install Build Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    git-lfs \
    curl \
    wget \
    unzip \
    libc6-i386 \
    lib32stdc++6 \
    lib32z1 \
    lib32ncurses6 \
    lib32gcc-s1 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Android SDK Command Line Tools
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget -q "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS}.zip" -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# Accept Android SDK Licenses
RUN yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --licenses 2>/dev/null || true

# Install Android SDK Components
RUN ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --update 2>/dev/null && \
    ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager \
    "platforms;android-${ANDROID_COMPILE_SDK}" \
    "build-tools;${ANDROID_BUILD_TOOLS}" \
    "platform-tools" \
    "extras;android;m2repository" \
    "extras;google;m2repository" 2>/dev/null || true

# Add Android SDK to PATH
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/build-tools/${ANDROID_BUILD_TOOLS}"

# Pre-configure SSH Known Hosts (GitHub, GitLab)
RUN mkdir -p /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts && \
    ssh-keyscan gitlab.com >> /root/.ssh/known_hosts && \
    chmod 700 /root/.ssh && \
    chmod 644 /root/.ssh/known_hosts

# Working Directory
WORKDIR /workspace

# Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD java -version 2>&1 | grep -q "17"

# Default Command - allows Jenkins Pipeline to execute commands
CMD ["/bin/bash"]