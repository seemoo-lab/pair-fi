FROM cimg/android:2024.11.1 AS toolchain

ARG FLUTTER_VERSION=3.22.3

ENV FLUTTER_HOME=/home/circleci/flutter
ENV PUB_CACHE=/home/circleci/.pub-cache
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"
ENV CI=true

USER circleci

RUN sdkmanager --sdk_root="${ANDROID_HOME}" \
      "platform-tools" \
      "platforms;android-35" \
      "build-tools;35.0.0" \
 && test -f "${ANDROID_HOME}/platforms/android-35/android.jar" \
 && test -x "${ANDROID_HOME}/build-tools/35.0.0/aapt2"

RUN git clone \
      --branch "${FLUTTER_VERSION}" \
      --depth 1 \
      https://github.com/flutter/flutter.git \
      "${FLUTTER_HOME}" \
 && flutter config --no-analytics \
 && flutter precache --android \
 && test "$(flutter --version --machine | jq -r '.frameworkVersion')" = "${FLUTTER_VERSION}"


# ------------------------------------------------------------
# Flutter project
# ------------------------------------------------------------

FROM toolchain AS project

WORKDIR /workspace/app

COPY --chown=circleci:circleci app/ ./

RUN rm -rf \
      .dart_tool \
      .flutter-plugins \
      .flutter-plugins-dependencies \
      .packages \
      build \
 && chmod +x android/gradlew \
 && flutter pub get \
 && test -d lib \
 && test -d android \
 && test -x android/gradlew \
 && test -f "${ANDROID_HOME}/platforms/android-35/android.jar"


# ------------------------------------------------------------
# Debug APK
# ------------------------------------------------------------

FROM project AS debug-build

WORKDIR /workspace/app

RUN flutter build apk --debug --no-pub


# ------------------------------------------------------------
# Release APK
# ------------------------------------------------------------

FROM project AS release-apks-build

WORKDIR /workspace/app

RUN COMMUNITY_BUILD=true flutter build apk --release --target-platform=android-arm64 --split-per-abi --no-pub


# ------------------------------------------------------------
# Export artifact
# ------------------------------------------------------------

FROM scratch AS debug-apk

COPY --from=debug-build /workspace/app/build/app/outputs/flutter-apk/app-debug.apk /app-debug.apk

FROM scratch AS release-apks

COPY --from=release-apks-build /workspace/app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk /app-arm64-v8a-release.apk
