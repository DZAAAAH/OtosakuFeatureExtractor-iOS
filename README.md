# 🎧 OtosakuFeatureExtractor

A lightweight Swift-based feature extraction library for transforming raw audio chunks into **log-Mel spectrograms**, suitable for use in CoreML and on-device inference.

Built with ❤️ for on-device audio intelligence.

---

## 📦 Installation

You can add `OtosakuFeatureExtractor` as a Swift Package dependency:

```swift
.package(url: "https://github.com/Otosaku/OtosakuFeatureExtractor-iOS.git", from: "1.0.1")
```

Then add it to the target dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "OtosakuFeatureExtractor", package: "OtosakuFeatureExtractor")
    ]
)
```

---

## 🔁 Audio Processing Pipeline

```
[Raw Audio Chunk (Float64)] 
       ↓ pre-emphasis
[Pre-emphasized audio] 
       ↓ STFT (with Hann window)
[STFT result (complex)]
       ↓ Power Spectrum
[|FFT|^2]
       ↓ Mel Filterbank Projection (matrix multiply)
[Mel energies]
       ↓ log(ε + x)
[Log-Mel Spectrogram]
       ↓ MLMultiArray
[CoreML-compatible tensor]
```

---

## 🧪 Usage

### 1. Initialize the Extractor

You must provide a directory containing:

- `filterbank.npy` — shape `[80, 201]`, float32 or float64
- `hann_window.npy` — shape `[400]`, float32 or float64

```swift
import OtosakuFeatureExtractor

let extractor = try OtosakuFeatureExtractor(directoryURL: featureFolderURL)
```

---

### 2. Process a Chunk of Audio

The input must be a raw audio chunk as `Array<Double>`, typically at 16kHz sample rate.

```swift
let logMel: MLMultiArray = try extractor.processChunk(chunk: audioChunk)
```

> `audioChunk` should be at least 400 samples long to match the FFT window size.

---

### 3. (Optional) Save Log-Mel Features to JSON

```swift
saveLogMelToJSON(logMel: features)
```

---

## 📚 Dependencies

- [Accelerate](https://developer.apple.com/documentation/accelerate) — for optimized DSP
- [CoreML](https://developer.apple.com/documentation/coreml)
- [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) — for bundled model asset handling
- [pocketfft](https://github.com/dhrebeniuk/pocketfft)
- [plain-pocketfft](https://github.com/dhrebeniuk/plain-pocketfft)

---

## 📁 File Structure

```
OtosakuFeatureExtractor/
├── Sources/
│   └── OtosakuFeatureExtractor/
│       ├── OtosakuFeatureExtractor.swift
├── filterbank.npy
├── hann_window.npy
```

---

## 🗣️ Attribution

Project by [@make1986](https://github.com/make1986) under the [Otosaku](https://github.com/Otosaku) brand.

---

## 🧪 License

MIT License
