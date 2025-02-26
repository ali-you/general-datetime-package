# Ambient Light for iOS and android

<a href="https://pub.dev/packages/ambient_light">
   <img src="https://img.shields.io/pub/v/ambient_light?label=pub.dev&labelColor=333940&logo=dart">
</a>
<a href="https://github.com/ali-you/ambient-light-plugin/issues">
   <img alt="Issues" src="https://img.shields.io/github/issues/ali-you/ambient-light-plugin?color=0088ff" />
</a>
<a href="https://github.com/ali-you/ambient-light-plugin/issues?q=is%3Aclosed">
   <img alt="Issues" src="https://img.shields.io/github/issues-closed/ali-you/ambient-light-plugin?color=0088ff" />
</a>
<!-- <a href="https://github.com/ali-you/ambient-light-plugin/pulls">
   <img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/ali-you/ambient-light-plugin?color=0088ff" />
</a> -->
<a href="https://github.com/ali-you/ambient-light-plugin/pulls">
   <img alt="GitHub Pull Requests" src="https://badgen.net/github/prs/ali-you/ambient-light-plugin" />
</a>
<a href="https://github.com/ali-you/ambient-light-plugin/blob/main/LICENSE" rel="ugc">
   <img src="https://img.shields.io/github/license/ali-you/ambient-light-plugin?color=#007A88&amp;labelColor=333940;" alt="GitHub">
</a>
<a href="https://github.com/ali-you/ambient-light-plugin">
   <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/ali-you/ambient-light-plugin">
</a>

A Flutter plugin to access ambient light sensor data on Android, iOS and macOS. This plugin allows
you to retrieve the current ambient light level and listen to continuous updates.

## Features

- **Android:** Uses the `SensorManager` to access the device's ambient light sensor.
- **iOS:** Uses `CoreMotion` to access the ambient light sensor data on compatible iOS devices.
- **macOS:** Uses `IOKit` to access the ambient light sensor data on compatible macOS devices.
- **Retrieve Current Light Level:** Get the current ambient light level as a single value.
- **Stream Light Level:** Listen to continuous updates of the ambient light level.

## Installation

To use this plugin, you can add it to your Flutter project in one of two ways:

### 1. Add to `pubspec.yaml`
Include the following dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  ambient_light: ^0.1.2
  
```

### 2. Add directly from the terminal
Run the following command to add the plugin directly to your project:

```bash
flutter pub add ambient_light
```

## Usage

Import the package and use the provided methods to get ambient light sensor data.

```dart
import 'package:ambient_light/ambient_light.dart';

void main() async {
  final AmbientLight _ambientLight = AmbientLight(frontCamera: true);
  
  // Get ambient light value
  double? lightLevel = await _ambientLight.currentAmbientLight();
  print('Ambient light level: $lightLevel');

  // Listen to ambient light sensor data stream
  _ambientLight.ambientLightStream.listen((double lightLevel) {
    print('Ambient light level: $lightLevel');
  });
}
```

**Note:**

- The frontCamera parameter is iOS only and allows you to specify whether to use the front or back camera for measuring ambient light. For other platforms, you can initialize with the default:
    ```dart
    final AmbientLight _ambientLight = AmbientLight();
    ```
- Checkout [Example](https://pub.dev/packages/ambient_light/example) for complete explanation

## Methods

```dart
Future<double?> currentAmbientLight();
```

Returns the current ambient light level as a double. Returns null if the sensor is not available.

```dart
Stream<double> get ambientLightStream;
```

Returns a stream of ambient light sensor data as double.

## iOS

For iOS, the plugin uses CoreMotion to access ambient light sensor data. You need to add the
following key to your `Info.plist` to request access to the camera, which is required for measuring
ambient light.

```xml

<key>NSCameraUsageDescription</key>
<string>We need access to the camera to measure ambient light.</string>

```

## Contributions

Contributions are welcome! Please submit a pull request or open an issue to discuss any changes.

## Licence

This project is licensed under the BSD 3-Clause License. See
the [LICENSE](https://github.com/ali-you/ambient-light-plugin?tab=BSD-3-Clause-1-ov-file)  file for
details.
