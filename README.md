# OtosakuFeatureExtractor-iOS 🎶

![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![CoreML](https://img.shields.io/badge/CoreML-2.0-blue.svg)
![Accelerate](https://img.shields.io/badge/Accelerate-4.0-green.svg)
![iOS](https://img.shields.io/badge/iOS-14.0%2B-lightgrey.svg)

Welcome to the **OtosakuFeatureExtractor-iOS** repository! This lightweight Swift library is designed for log-Mel spectrogram extraction, leveraging the power of Accelerate and CoreML. With this tool, you can efficiently process audio signals and extract features for various applications in audio analysis and on-device AI.

## Table of Contents

1. [Features](#features)
2. [Installation](#installation)
3. [Usage](#usage)
4. [Example](#example)
5. [Contributing](#contributing)
6. [License](#license)
7. [Releases](#releases)
8. [Contact](#contact)

## Features

- **Lightweight**: Minimal footprint for fast performance.
- **Swift-based**: Easy integration into your iOS projects.
- **CoreML Support**: Seamless compatibility with machine learning models.
- **Accelerate Framework**: Utilizes Apple's Accelerate framework for optimized performance.
- **Log-Mel Spectrogram Extraction**: Perfect for audio signal processing and speech analysis.
- **On-Device AI**: Enables real-time processing without server dependency.

## Installation

To get started with **OtosakuFeatureExtractor-iOS**, you can clone the repository or add it as a dependency in your project.

### Using CocoaPods

Add the following line to your Podfile:

```ruby
pod 'OtosakuFeatureExtractor-iOS'
```

Then run:

```bash
pod install
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/DZAAAAH/OtosakuFeatureExtractor-iOS.git
   ```
2. Drag and drop the `OtosakuFeatureExtractor` folder into your Xcode project.

## Usage

To use the library, simply import it into your Swift files:

```swift
import OtosakuFeatureExtractor
```

You can then create an instance of the feature extractor and start processing audio files. 

### Basic Example

Here’s a simple example of how to extract a log-Mel spectrogram from an audio file:

```swift
let audioFilePath = "path/to/audio/file.wav"
let featureExtractor = OtosakuFeatureExtractor()

do {
    let spectrogram = try featureExtractor.extractSpectrogram(from: audioFilePath)
    print("Spectrogram: \(spectrogram)")
} catch {
    print("Error extracting spectrogram: \(error)")
}
```

## Example

To see the library in action, you can explore the example project included in the repository. This project demonstrates how to integrate the feature extractor into a simple iOS app.

### Running the Example

1. Open the example project in Xcode.
2. Run the project on a simulator or device.
3. Select an audio file and observe the extracted log-Mel spectrogram displayed in the app.

## Contributing

We welcome contributions to **OtosakuFeatureExtractor-iOS**! If you would like to contribute, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and commit them.
4. Push your branch and create a pull request.

Please ensure that your code adheres to the project's coding standards and includes appropriate tests.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Releases

To download the latest release, please visit the [Releases section](https://github.com/DZAAAAH/OtosakuFeatureExtractor-iOS/releases). Here, you can find compiled binaries and other resources for your use.

## Contact

For any inquiries or feedback, feel free to reach out via GitHub issues or contact the maintainer directly. Your input is valuable for the continuous improvement of this library.

---

Thank you for exploring **OtosakuFeatureExtractor-iOS**! We hope this library serves your audio processing needs effectively. If you encounter any issues or have suggestions for improvements, please don't hesitate to let us know. Happy coding!