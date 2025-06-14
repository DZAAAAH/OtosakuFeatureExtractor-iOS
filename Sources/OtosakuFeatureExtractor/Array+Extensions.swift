//
//  Array+Extensions.swift
//  OtosakuFeatureExtractor
//
//  Created by Marat Zainullin on 12/06/2025.
//


import Foundation
import Accelerate

internal import PocketFFT
internal import PlainPocketFFT
import CoreGraphics

extension FloatingPoint {
    
    var byteArray: [UInt8] {
        var value = self
        return withUnsafeBytes(of: &value) { Array($0) }
    }
        
    static func MEL<T: FloatingPoint>(fromHZ frequency: T) -> T {
        let fmin = T(0)
        let fsp = T(200) / T(3)

        var mels = (frequency - fmin) / fsp

        let minLogHZ = T(1000)
        let minLogMEL = (minLogHZ - fmin) / fsp
        let logStep = ((T(64)/T(10)).logarithm() as T)/T(27)
        
        if frequency >= minLogHZ {
            mels = minLogMEL + (frequency / minLogHZ).logarithm() / logStep
        }
        
        return mels
    }
    
    static func HZ<T: FloatingPoint>(fromMEL mels: T) -> T {
        let fmin = T(0)
        let fsp = T(200) / T(3)

        var freqs = fmin + fsp*mels
        
        let minLogHZ = T(1000)
        let minLogMEL = (minLogHZ - fmin) / fsp
        
        let logStep = ((T(64)/T(10)).logarithm() as T)/T(27)

        if mels >= minLogMEL {
            let exponent = (logStep as T * (mels - minLogMEL)).exponent() as T
            freqs = minLogHZ*exponent
        }
        
        return freqs
    }
    
    func logarithm10<T: FloatingPoint>() -> T {
        switch self {
        case let self as Double:
            return log10(self) as? T ?? 0
        case let self as CGFloat:
            return log10f(Float(self)) as? T ?? 0
        case let self as Float:
            return log10f(Float(self)) as? T ?? 0
        default:
            return 0 as T
        }
    }
    
    func logarithm<T: FloatingPoint>() -> T {
        switch self {
        case let self as Double:
            return log(self) as? T ?? 0
        case let self as CGFloat:
            return logf(Float(self)) as? T ?? 0
        case let self as Float:
            return logf(Float(self)) as? T ?? 0
        default:
            return 0 as T
        }
    }
    
    func exponent<T: FloatingPoint>() -> T {
        switch self {
        case let self as Double:
            return exp(self) as? T ?? 0
        case let self as CGFloat:
            return expf(Float(self)) as? T ?? 0
        case let self as Float:
            return expf(Float(self)) as? T ?? 0
        default:
            return 0 as T
        }
    }
    
    func cosine<T: FloatingPoint>() -> T {
        switch self {
        case let self as Double:
            return cos(-self) as? T ?? 0
        case let self as CGFloat:
            return cosf(-Float(self)) as? T ?? 0
        case let self as Float:
            return cosf(-Float(self)) as? T ?? 0
        default:
            return 0 as T
        }
    }
    
}

extension Array {
    
    static func multplyVector(matrix1: [[Double]], matrix2: [[Double]]) -> [[Double]] {
        let newMatrixCols = matrix1.count
        let newMatrixRows = matrix2.first?.count ?? 1
        
        var result = [Double](repeating: 0.0, count: newMatrixCols*newMatrixRows)
        
        let flatMatrix1 = matrix1.flatMap { $0 }
        let flatMatrix2 = matrix2.flatMap { $0 }
        
        for index in 0..<result.count {
            result[index] = flatMatrix2[index]*flatMatrix1[index/newMatrixRows]
        }
        
        let matrixResult = result.chunked(into: newMatrixRows)
        
        return matrixResult
    }
    
    static func divideVector(matrix1: [[Double]], matrix2: [[Double]]) -> [[Double]] {
        let newMatrixCols = matrix1.count
        let newMatrixRows = matrix2.first?.count ?? 1
        
        var result = [Double](repeating: 0.0, count: newMatrixCols*newMatrixRows)
        
        let flatMatrix1 = matrix1.flatMap { $0 }
        let flatMatrix2 = matrix2.flatMap { $0 }
        
        for index in 0..<result.count {
            result[index] = flatMatrix2[index]/flatMatrix1[index/newMatrixRows]
        }
        
        let matrixResult = result.chunked(into: newMatrixRows)
        
        return matrixResult
    }
    
    static func divideFlatVector<T: FloatingPoint>(matrix1: [T], matrix2: [T]) -> [T] {
        let minCount = Swift.min(matrix1.count, matrix2.count)
        
        var result = [T](repeating: 0, count: minCount)
        
        for index in 0..<minCount {
            result[index] = matrix1[index]/matrix2[index]
        }
        
        return result
    }
    
    static func minimumFlatVector<T: FloatingPoint>(matrix1: [T], matrix2: [T]) -> [T] {
        let minCount = Swift.min(matrix1.count, matrix2.count)
        
        var result = [T](repeating: 0, count: minCount)
        
        for index in 0..<minCount {
            result[index] = Swift.min(matrix1[index], matrix2[index])
        }
        
        return result
    }
    
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
}

extension Array where Element == [Double] {
    
    var transposed: [[Double]] {
        let matrix = self
        let newMatrixCols = matrix.count
        let newMatrixRows = matrix.first?.count ?? 1
        
        var results = [Double](repeating: 0.0, count: newMatrixCols*newMatrixRows)
        
        vDSP_mtransD(matrix.flatMap { $0 }, 1, &results, 1, vDSP_Length(newMatrixRows), vDSP_Length(newMatrixCols))
        
        return results.chunked(into: newMatrixCols)
    }
    
    func multiplyVector(matrix: [Element]) -> [Element] {
        let newMatrixCols = self.count
        let newMatrixRows = matrix.first?.count ?? 1
        
        var result = [Double](repeating: 0.0, count: newMatrixCols*newMatrixRows)
        
        let flatMatrix1 = self.flatMap { $0 }
        let flatMatrix2 = matrix.flatMap { $0 }
        
        for index in 0..<result.count {
            result[index] = flatMatrix2[index]*flatMatrix1[index/newMatrixRows]
        }
        
        let matrixResult = result.chunked(into: newMatrixRows)
        
        return matrixResult
    }
    
    func dot(matrix: [Element]) -> [Element] {
        let matrixRows = matrix.count
        let matrixCols = matrix.first?.count ?? 1
        
        let selfMatrixRows = self.count
        
        var result = [Double](repeating: 0.0, count: Int(selfMatrixRows * matrixCols))
        
        let flatMatrix1 = self.flatMap { $0 }
        let flatMatrix2 = matrix.flatMap { $0 }
        
        vDSP_mmulD(flatMatrix1, 1, flatMatrix2, 1, &result, 1, vDSP_Length(selfMatrixRows), vDSP_Length(matrixCols), vDSP_Length(matrixRows))
        
        return result.chunked(into: Int(matrixCols))
    }
}


extension Array where Element == [(real: Double, imagine: Double)] {
    
    var transposed: [Element] {
        let matrix = self
        let newMatrixCols = matrix.count
        let newMatrixRows = matrix.first?.count ?? 1
        
        var resultsCols = [[(real: Double, imagine: Double)]].init(repeating: [(real: Double, imagine: Double)](), count: newMatrixRows)
        
        for col in 0..<newMatrixRows {
            var resultsRows = [(real: Double, imagine: Double)].init(repeating: (real: 0.0, imagine: 0.0), count: newMatrixCols)
            for row in 0..<newMatrixCols {
                resultsRows[row] = matrix[row][col]
            }
            resultsCols[col] = resultsRows
        }
        
        return resultsCols
    }
    
}



extension Array where Iterator.Element: FloatingPoint {
    
    func floatingPointStrided(shape: (width: Int, height: Int), stride: (xStride: Int, yStride: Int)? = nil) -> [[Element]] {
        var resultArray: [[Element]] = []
        
        let byteStrideX = stride?.xStride ?? 1
        let byteStrideY = stride?.yStride ?? shape.height

        for yIndex in 0..<shape.width {
            var lineArray = [Element]()
            for xIndex in 0..<shape.height {
                let value = self[(yIndex+xIndex)%self.count]
                
                lineArray.append(value)
            }
            resultArray.append(lineArray)
        }
        
        return resultArray
    }
    
    func strided(shape: (width: Int, height: Int), stride: (xStride: Int, yStride: Int)? = nil) -> [[Element]] {
        let elementSize = MemoryLayout<Element>.size
        return floatingPointStrided(shape: shape, stride: (xStride: (stride?.xStride ?? elementSize)/elementSize, yStride:  (stride?.yStride ?? elementSize)/elementSize))
    }
    
    var diff: [Element] {
        var diff = [Element]()
        
        for index in 1..<self.count {
            let value = self[index]-self[index-1]
            diff.append(value)
        }
        
        return diff
    }
    
    func outerSubstract(array: [Element]) -> [[Element]] {
        var result = [[Element]]()
        
        let rows = self.count
        let cols = array.count
        
        for row in 0..<rows {
            var rowValues = [Element]()
            for col in 0..<cols {
                let value = self[row] - array[col]
                rowValues.append(value)
            }
            
            result.append(rowValues)
        }
        
        return result
    }
    
    func powerToDB(ref: Element = Element(1), amin: Element = Element(1)/Element(Int64(10000000000)), topDB: Element = Element(80)) -> [Element] {
        let ten = Element(10)
        
        let logSpec = map { ten * (Swift.max(amin, $0)).logarithm10() - ten * (Swift.max(amin, abs(ref))).logarithm10() }
        
        let maximum = (logSpec.max() ?? Element(0))
        
        return logSpec.map { Swift.max($0, maximum - topDB) }
    }
    
    func normalizeAudioPower() -> [Element] {
        var dbValues = powerToDB()
        
        let minimum = (dbValues.min() ?? Element(0))
        dbValues = dbValues.map { $0 -  minimum}
        let maximun = (dbValues.map { abs($0) }.max() ?? Element(0))
        dbValues = dbValues.map { $0/(maximun + Element(1)) }
        return dbValues
    }
    
}

extension Array where Iterator.Element == Double {
    
    func frame(frameLength: Int = 2048, hopLength: Int = 512) -> [[Element]] {
        let framesCount = 1 + (self.count - frameLength) / hopLength
        let strides = MemoryLayout.size(ofValue: Double(0))
        
        let outputShape = (width: self.count - frameLength + 1, height: frameLength)
        let outputStrides = (xStride: strides*hopLength, yStride: strides)
        
        let verticalSize = Int(ceil(Float(outputShape.width)/Float(hopLength)))
        
        var xw = [[Double]]()
        
        for yIndex in 0..<verticalSize {
            var lineArray = [Double]()
            
            for xIndex in 0..<frameLength {
                let value = self[((yIndex*hopLength)+xIndex)%self.count]
                
                lineArray.append(value)
            }
            xw.append(lineArray)
        }
        
        return xw.transposed
    }
    
}


extension Array where Iterator.Element: FloatingPoint {
    
    static func empty(width: Int, height: Int, defaultValue: Element) -> [[Element]] {
        var result: [[Element]] = [[Element]]()
        
        for _ in 0..<width {
            var vertialArray: [Element] = [Element]()
            for _ in 0..<height {
                vertialArray.append(defaultValue)
            }
            result.append(vertialArray)
        }
        
        return result
    }
    
    static func zeros(length: Int) -> [Element] {
        var result: [Element] = [Element]()
        
        for _ in 0..<length {
            result.append(Element.zero)
        }
        
        return result
    }
    
    
    func reflectPad(fftSize: Int) -> [Element] {
        var array = [Element]()
        
        let leftPaddingCount = fftSize / 2
        for i in 0..<leftPaddingCount {
            array.append(self[leftPaddingCount - i])
        }
        
        array.append(contentsOf: self)
        
        let rightPaddingCount = fftSize / 2
        for i in 0..<rightPaddingCount {
            array.append(self[self.count - 2 - i])
        }
        
        return array
    }
    
    static func linespace(start: Element, stop: Element, num: Element) -> [Element] {
        var linespace = [Element]()
        
        let one = num/num
        var index = num*0
        while index < num-one {
            let startPart = (start*(one - index/floor(num - one)))
            let stopPart = (index*stop/floor(num - one))
            
            let value = startPart + stopPart
            
            linespace.append(value)
            index += num/num
        }
        
        linespace.append(stop)
        
        return linespace
    }
    
    
    
}



extension Array where Element == [Double] {
    
    var rfft: [[(real: Double, imagine: Double)]] {
        let transposed = self.transposed
        let cols = transposed.count
        let rows = transposed.first?.count ?? 1
        let rfftRows = rows/2 + 1
        
        var flatMatrix = transposed.flatMap { $0 }
        let rfftCount = rfftRows*cols
        var resultComplexMatrix = [Double](repeating: 0.0, count: (rfftCount + cols + 1)*2)
        
        resultComplexMatrix.withUnsafeMutableBytes { destinationData -> Void in
            let destinationDoubleData = destinationData.bindMemory(to: Double.self).baseAddress
            flatMatrix.withUnsafeMutableBytes { (flatData) -> Void in
                let sourceDoubleData = flatData.bindMemory(to: Double.self).baseAddress
                execute_real_forward(sourceDoubleData, destinationDoubleData, npy_intp(Int32(cols)), npy_intp(Int32(rows)), 1)
            }
        }
        
        var realMatrix = [Double](repeating: 0.0, count: rfftCount)
        var imagineMatrix = [Double](repeating: 0.0, count: rfftCount)
        
        for index in 0..<rfftCount {
            let real = resultComplexMatrix[index*2]
            let imagine = resultComplexMatrix[index*2+1]
            realMatrix[index] = real
            imagineMatrix[index] = imagine
        }
        
        let resultRealMatrix = realMatrix.chunked(into: rfftRows).transposed
        let resultImagineMatrix = imagineMatrix.chunked(into: rfftRows).transposed
        
        var result = [[(real: Double, imagine: Double)]]()
        for row in 0..<resultRealMatrix.count {
            let realMatrixRow = resultRealMatrix[row]
            let imagineMatrixRow = resultImagineMatrix[row]
            
            var resultRow = [(real: Double, imagine: Double)]()
            for col in 0..<realMatrixRow.count {
                resultRow.append((real: realMatrixRow[col], imagine: imagineMatrixRow[col]))
            }
            result.append(resultRow)
        }
        
        return result
    }
    
    func normalizeAudioPowerArray() -> [[Double]] {
        let chunkSize = self.first?.count ?? 0
        let dbValues = self.flatMap { $0 }.normalizeAudioPower().chunked(into: chunkSize)
        return dbValues
    }
}


public extension Array where Element == Double {
    
    func padCenter(input: [[Double]], to size: Int) -> [[Double]] {
        let diff = size - input.count
        var array = [[Double]]()
        
        array.append(contentsOf: [[Double]].init(repeating: [0], count: diff/2))
        array.append(contentsOf: input)
        array.append(contentsOf: [[Double]].init(repeating: [0], count: diff/2))
        
        return array
        
    }
    
    
    func stft(nFFT: Int = 400, hopLength: Int = 160, window: [[Double]]) -> [[(real: Double, imagine: Double)]] {
        
        let centered = self.reflectPad(fftSize: nFFT)
        
        
        let yFrames = centered.frame(frameLength: nFFT, hopLength: hopLength)
        
        let matrix = window.multiplyVector(matrix: yFrames)
        
        let result = matrix.rfft
        
        return result
    }
    
    
}
