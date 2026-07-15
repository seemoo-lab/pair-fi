
[![Android Application](https://github.com/seemoo-lab/pair-fi/actions/workflows/application-build.yml/badge.svg)](https://github.com/seemoo-lab/pair-fi/actions/workflows/application-build.yml)
[![Nexmon Wi-Fi Firmware](https://github.com/seemoo-lab/pair-fi/actions/workflows/firmware-build.yml/badge.svg)](https://github.com/seemoo-lab/pair-fi/actions/workflows/firmware-build.yml)

# Pair-Fi: Integrity Code Protected Secure Device Pairing via SDR-Enabled Wi-Fi Chips on Smartphones

Pair-Fi is a research prototype for secure group pairing between nearby smartphones. It uses Wi-Fi Direct for regular data exchange and an integrity-coded radio-frequency out-of-band channel for PHY layer authentication. The out-of-band channel is implemented through SDR-like transmission and reception capabilities added directly to the smartphones' Wi-Fi firmware.

Pair-Fi consists of two components:

- **Android application:** the user interface and secure group-pairing protocol.
- **Nexmon firmware patch:** enables integrity-code transmission and raw IQ-sample reception on the Wi-Fi chip.

The prototype currently targets and has been tested on **Google Pixel 7** devices with the **BCM4389c1** Wi-Fi chip and Wi-Fi firmware version **20_101_57_r1035009**.

> [!WARNING]
> The firmware is device- and firmware-version-specific. Do not install it on unsupported hardware or a different firmware version. 

No prebuilt APK or firmware module is distributed. Both components must be built from source.

## Quick start

The recommended setup uses Docker for both builds. Docker with Buildx support and ADB are required.

#### 1. Build and install the firmware

```bash
cd firmware && ./docker/build.sh
```

Output:
```text
firmware/out/pairfi-nexmon-magisk.zip
```

> [!NOTE]
> The firmware can alternatively be built with a local setup of the [Nexmon framework](https://github.com/seemoo-lab/nexmon). Follow the frameworks README. Then copy `firmware/pairfi-nexmon-patch/` into `nexmon/patches/bcm4389c1/20_101_57_r1035009/pairfi/` and perform a `make` inside that patch directory.

The build module requires a device rooted with [Magisk](https://github.com/topjohnwu/Magisk) **v29 or newer**. Magisk is used to replace the Wi-Fi firmware located in Android's read-only system partition.

Connect one or more supported phones through ADB, then run from `firmware/`:
```bash
./scripts/install-magisk-module-via-adb.sh out/pairfi-nexmon-magisk.zip
```

The script detects connected devices and asks which ones should receive the module.

> [!NOTE]
> Instead of rooting the device, the patched firmware may be integrated into a compatible custom ROM. That process is device- and ROM-specific and is not automated by this repository.

#### 2. Build and install the application

```bash
cd application && ./docker/build.sh
```

Output:

```text
application/dist/app-arm64-v8a-release.apk
```

Install it through ADB:

```bash
adb install application/dist/app-arm64-v8a-release.apk
```

> [!NOTE]
> The application can alternatively be built and run with Android Studio. See the [application documentation](application/README.md) for the required Flutter, Java, and Android SDK versions.

#### 3. Use Pair-Fi

Install both the firmware module and the application on every participating phone. Start the Pair-Fi application, create a local profile, select one device as the **coordinator** and the remaining devices as **participants**, and follow the on-screen instructions.

## Reference this project
Any use of this project which results in an academic publication or other publication which includes a bibliography should include a citation to our Pair-Fi paper:  
> Jakob Link, Florentin Putz, and Matthias Hollick. [**Pair-Fi: Integrity Code Protected Secure Device Pairing via SDR-Enabled Wi-Fi Chips on Smartphones**.](https://doi.org/10.1145/3765613.3811679) In Proceedings of the _19th ACM Conference on Security and Privacy in Wireless and Mobile Networks (WiSec '26)_, June, 2026. [https://doi.org/10.1145/3765613.3811679](https://doi.org/10.1145/3765613.3811679)

Citation metadata is also available in [`CITATION.cff`](CITATION.cff).

```bibtex
@inproceedings{link2026pairfi,
author = {Link, Jakob and Putz, Florentin and Hollick, Matthias},
title = {Pair-Fi: Integrity Code Protected Secure Device Pairing via SDR-Enabled Wi-Fi Chips on Smartphones},
year = {2026},
publisher = {Association for Computing Machinery},
address = {New York, NY, USA},
url = {https://doi.org/10.1145/3765613.3811679},
doi = {10.1145/3765613.3811679},
booktitle = {Proceedings of the 19th ACM Conference on Security and Privacy in Wireless and Mobile Networks},
pages = {74–85},
location = {Germany},
series = {WiSec '26}
}
```

## Licenses

- The [Android application](application/LICENSE.txt) is licensed under the Apache License 2.0.
- The [firmware patch](firmware/LICENSE.txt) is licensed under the GNU General Public License v3.0.

## Contact
- [Jakob Link](https://www.seemoo.tu-darmstadt.de/team/jlink/) <jlink@seemoo.de>
- [Florentin Putz](https://fputz.net/) <fputz@seemoo.de>
