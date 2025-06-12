// The Swift Programming Language
// https://docs.swift.org/swift-book



import CoreML
import Foundation
import Accelerate

func matmul_vDSP(_ A: [[Double]], _ B: [[Double]]) -> [[Double]] {
    let m = A.count
    let n = B[0].count
    let k = A[0].count
    
    let flatA = A.flatMap { $0 }
    let flatB = B.flatMap { $0 }
    var flatC = [Double](repeating: 0.0, count: m * n)
    
    vDSP_mmulD(
        flatA, 1,
        flatB, 1,
        &flatC, 1,
        vDSP_Length(m),
        vDSP_Length(n),
        vDSP_Length(k)
    )
    
    var result: [[Double]] = []
    for row in 0..<m {
        let start = row * n
        let end = start + n
        result.append(Array(flatC[start..<end]))
    }
    
    return result
}

func saveLogMelToJSON(logMel: [[Float]], filename: String = "log_mel_output.json") {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    
    let logMelDouble = logMel.map { $0.map { Double($0) } }
    
    do {
        let data = try encoder.encode(logMelDouble)
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        
        try data.write(to: url)
        print("✅ Сохранено в: \(url)")
    } catch {
        print("❌ Ошибка сохранения JSON: \(error)")
    }
}

enum HannWindowError: Error {
    case fileLoadFailed(URL)
    case invalidHeader
    case unexpectedElementSize(Int)
}


enum ProcessChunkError: Error {
    case conversionFailed(String)
    case unexpectedChunkSize(Int)
    case filterbankError(String)
}

enum InitError: Error {
    case urlError
}

@available(macOS 10.14, *)
public class OtosakuFeatureExtractor {
    private let TAG: String = "OtosakuFeatureExtractor"
    private let nFFT: Int = 400
    private let hopLength: Int = 160
    
    private var filterbank:  [[Double]]
    private var hannWindow: [[Double]]
    
    public init (directoryURL: URL) throws {
        let filterbankURL = directoryURL.appendingPathComponent("filterbank.npy")
        let hannWindowURL = directoryURL.appendingPathComponent("hann_window.npy")
        filterbank = try OtosakuFeatureExtractor.loadFilterbank(url: filterbankURL)
        hannWindow = try OtosakuFeatureExtractor.loadHannWindow(url: hannWindowURL)
        print(TAG, "filterbank.npy loaded")
        print(TAG, "hann_window.npy loaded")
    }
    
    public func processChunk(chunk: [Double]) throws -> MLMultiArray {
        
        var chunk = chunk
        preemphasisInPlace(samples: &chunk)
        
        let stft = chunk.stft(nFFT: nFFT, hopLength: hopLength, window: hannWindow)
        let flatten_fft = get_flatten_fft(stft: stft)
        let appFilterbank = matmul_vDSP(filterbank, flatten_fft)
        let appLog = logTransform2D(input: appFilterbank)
        
        return try convertToMLMultiArray(array: appLog)
        
    }
    
    public func expandDims2D(array: MLMultiArray) throws -> MLMultiArray {
        let originalShape = array.shape.map { $0.intValue }
        let newShape = [1, 1] + originalShape
        
        let reshaped = try MLMultiArray(
            dataPointer: array.dataPointer,
            shape: newShape.map { NSNumber(value: $0) },
            dataType: array.dataType,
            strides: computeStrides(shape: newShape, dataType: array.dataType),
            deallocator: nil
        )
        return reshaped
    }
    
    private func logTransform2D(input: [[Double]], epsilon: Double = pow(2.0, -24.0)) -> [[Double]] {
        return input.map { row -> [Double] in
            var eps = epsilon
            var result = [Double](repeating: 0.0, count: row.count)
            
            // row + ε
            vDSP_vsaddD(row, 1, &eps, &result, 1, vDSP_Length(row.count))
            
            // log(row + ε)
            var count = Int32(row.count)
            vvlog(&result, result, &count)
            
            return result
        }
    }
    
    
    
    private func computeStrides(shape: [Int], dataType: MLMultiArrayDataType) -> [NSNumber] {
        var strides = [Int](repeating: 0, count: shape.count)
        strides[shape.count - 1] = 1
        for i in (0..<(shape.count - 1)).reversed() {
            strides[i] = strides[i + 1] * shape[i + 1]
        }
        return strides.map { NSNumber(value: $0) }
    }
    
    private func convertToMLMultiArray(array: [[Double]]) throws -> MLMultiArray {
        let originalRows = array.count
        let originalCols = array.first?.count ?? 0
        
        // Меняем местами строки и столбцы для транспонирования
        let transposedRows = originalCols
        let transposedCols = originalRows
        
        do {
            let shape: [NSNumber] = [1, NSNumber(value: transposedRows), NSNumber(value: transposedCols)]
            let multiArray = try MLMultiArray(shape: shape, dataType: .float32)
            
            for i in 0..<transposedRows {
                for j in 0..<transposedCols {
                    let value = Float32(array[j][i])
                    multiArray[[0, NSNumber(value: i), NSNumber(value: j)]] = NSNumber(value: value)
                }
            }
            
            return multiArray
        } catch {
            throw ProcessChunkError.conversionFailed(error.localizedDescription)
        }
    }
    
    
    private func get_flatten_fft(stft: [[(real: Double, imagine: Double)]]) -> [[Double]] {
        var out: [[Double]] = []
        
        for row in stft {
            var r: [Double] = []
            for item in row {
                r.append(pow(item.real, 2) + pow(item.imagine, 2))
            }
            out.append(r)
        }
        
        return out
    }
    
    private func preemphasisInPlace(samples: inout [Double], coeff: Double = 0.97) {
        guard samples.count > 1 else { return }
        
        for i in stride(from: samples.count - 1, to: 0, by: -1) {
            samples[i] -= coeff * samples[i - 1]
        }
    }
    
    private static func loadFilterbank(url: URL) throws -> [[Double]] {
        
        let rows = 80
        let cols = 201
        guard let data = try? Data(contentsOf: url) else {
            throw HannWindowError.fileLoadFailed(url)
        }
        guard let headerEndIndex = data.firstIndex(of: 0x0A) else {
            throw HannWindowError.invalidHeader
        }
        let validData = data.dropFirst(headerEndIndex + 1)
        let elementSize = validData.count / (rows * cols)
        if elementSize == 8 {
            let flatArray: [Double] = validData.withUnsafeBytes { pointer in
                let buffer = pointer.bindMemory(to: Double.self)
                return Array(buffer)
            }
            guard flatArray.count == rows * cols else {
                throw HannWindowError.unexpectedElementSize(flatArray.count)
            }
            
            return stride(from: 0, to: flatArray.count, by: cols).map {
                Array(flatArray[$0..<$0 + cols])
            }
        } else if elementSize == 4 {
            let flatArray: [Double] = validData.withUnsafeBytes { pointer in
                let buffer = pointer.bindMemory(to: Float.self)
                return buffer.map { Double($0) }
            }
            guard flatArray.count == rows * cols else {
                throw HannWindowError.unexpectedElementSize(flatArray.count)
            }
            
            let doubleArray = flatArray.map { Double($0) }
            return stride(from: 0, to: doubleArray.count, by: cols).map {
                Array(doubleArray[$0..<$0 + cols])
            }
        } else {
            throw HannWindowError.unexpectedElementSize(elementSize)
        }
    }
    
    
    private static func loadHannWindow(url: URL) throws -> [[Double]] {
        guard let data = try? Data(contentsOf: url) else {
            throw HannWindowError.fileLoadFailed(url)
        }
        guard let headerEndIndex = data.firstIndex(of: 0x0A) else {
            throw HannWindowError.invalidHeader
        }
        let validData = data.dropFirst(headerEndIndex + 1)
        let elementSize = validData.count / 400
        if elementSize == 8 {
            let flatArray: [Double] = validData.withUnsafeBytes { pointer in
                let buffer = pointer.bindMemory(to: Double.self)
                return Array(buffer)
            }
            return flatArray.map { [$0] }
        } else if elementSize == 4 {
            let flatArray: [Double] = validData.withUnsafeBytes { pointer in
                let buffer = pointer.bindMemory(to: Float.self)
                return buffer.map { Double($0) }
            }
            return flatArray.map { [$0] }
        } else {
            throw HannWindowError.unexpectedElementSize(elementSize)
        }
    }
    
}
