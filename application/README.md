<h1 align="center">Pair-Fi App</h1>

**Pair-Fi** is an open-source smartphone app, based on [**PairSonic**](https://github.com/seemoo-lab/pairsonic), that enables two or more users meeting in person to spontaneously exchange or verify their contact information.
Pair-Fi supports the secure exchange of cryptographic public keys, which is crucial for protecting end-to-end encrypted communication, e.g., in messenger apps (so called *authentication ceremony*).

Pair-Fi simplifies the pairing process by automating the tedious verification tasks of previous methods through an *integrity-coded RF out-of-band* channel using smartphones' built-in W-Fi hardware.
It does not rely on external key management infrastructure, prior associations, or shared secrets.

While the application is fully functional, this project is meant to be a proof-of-concept.
In its current state, the Pair-Fi app was only tested on Google Pixel 7 devices.
The Pair-Fi app depends on modified Wi-Fi firmware that needs to be installed separately.

## Using PairFi

This repository contains a demo implementation of the Pair-Fi contact exchange protocol.
The app is written in Flutter and targets Android devices (Google Pixel 7).
Try it out yourself by following the build instructions below and installing the app.

When you start the app, you can create a profile (name, avatar, bio) and exchange it with nearby users. The app itself doesn't have any functionality besides implementing the contact exchange, so you cannot do much with your newly exchanged contacts yet.

In the future, Pair-Fi could be integrated into other apps as an option for in-person contact exchange/verification.

## Build & Develop

### Using Docker

On a Unix machine with Docker installed and running, run `./docker/build.sh` to build the app image.  
Once finished, install the app on a smartphone, e.g. via ADB: `adb install dist/app-arm64-v8a-release.apk`.

### Using Android Studio

Requirements:
- Flutter 3.22
- Java 17
- Android SDK 35

In order to build & run the app, make sure to have [Android Studio](https://developer.android.com/studio) installed and set up. For Android Studio, the [Flutter](https://plugins.jetbrains.com/plugin/9212-flutter) and [Dart](https://plugins.jetbrains.com/plugin/6351-dart) plugins are recommended. Then, either run `flutter run` or click the play button next to the main function in [lib/main.dart](lib/main.dart) in Android Studio and choose "Run main.dart".

## Powered by
The Pair-Fi protocol is based on the secure foundation of the excellent [SafeSlinger](https://doi.org/10.1145/2500423.2500428) protocol and [PairSonic](https://github.com/seemoo-lab/pairsonic).

## Authors
- **Jakob Link** ([email](mailto:jlink@seemoo.de), [web](https://www.seemoo.tu-darmstadt.de/team/jlink/))
- **Florentin Putz** ([email](mailto:fputz@seemoo.de), [web](https://fputz.net))
- **Matthias Hollick**

## References
Jakob Link, Florentin Putz, and Matthias Hollick. **Pair-Fi: Integrity Code Protected Secure Device Pairing via SDR-Enabled Wi-Fi Chips on Smartphones**. In Proceedings of the *19th ACM Conference on Security and Privacy in Wireless and Mobile Networks (WiSec '26)*, June, 2026. [https://doi.org/10.1145/3765613.3811679](https://doi.org/10.1145/3765613.3811679)

## License
The Pair-Fi App is released under the [Apache-2.0](LICENSE) license.
