import Foundation
import MetalKit

let device = MTLCreateSystemDefaultDevice()
let commandQueue = device?.makeCommandQueue()
let library = device?.makeDefaultLibrary()

let compute_kernel = library?.makeFunction(name: "computeArray")
var computePipeline: MTLComputePipelineState!

do {
    computePipeline = try device?.makeComputePipelineState(function: compute_kernel!)
}
catch {
    print(error)
}

let nbElements = 5000000

func randomArray() -> [Float] {
    
    var array: [Float] = []
    
    for _ in (0..<nbElements) {
        array.append(Float.random(in: 1..<100))
    }
    
    return array
}

let a1 = randomArray()
let a2 = randomArray()

let array1 = device?.makeBuffer(bytes: a1, length: MemoryLayout<Float>.size * nbElements, options: .storageModeShared)
let array2 = device?.makeBuffer(bytes: a2, length: MemoryLayout<Float>.size * nbElements, options: .storageModeShared)
let result = device?.makeBuffer(length: nbElements, options: .storageModeShared)

let commandBuffer = commandQueue?.makeCommandBuffer()
let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
commandEncoder?.setComputePipelineState(computePipeline)
commandEncoder?.setBuffer(array1, offset: 0, index: 0)
commandEncoder?.setBuffer(array2, offset: 0, index: 1)
commandEncoder?.setBuffer(result, offset: 0, index: 2)

print("Beginning computation (GPU)")
var start = CFAbsoluteTimeGetCurrent()

let threadsPerGrid = MTLSize(width: nbElements, height: 1, depth: 1)
let maxThreads = computePipeline!.maxTotalThreadsPerThreadgroup
let threadsGroup = MTLSize(width: maxThreads, height: 1, depth: 1)
commandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsGroup)
commandEncoder?.endEncoding()
commandBuffer?.commit()
commandBuffer?.waitUntilCompleted()

var resultBuffer = result?.contents().bindMemory(to: Float.self, capacity: MemoryLayout<Float>.size * nbElements)
for i in (0..<5) {
    print("\(a1[i]) + \(a2[i]) = \(Float(resultBuffer!.pointee) as Any)")
    resultBuffer = resultBuffer?.advanced(by: 1)
}

var elapsed = CFAbsoluteTimeGetCurrent() - start
print("Elapsed with metal: \(elapsed) with \(nbElements) elements")
print("")
print("Beginning computation (CPU)")
start = CFAbsoluteTimeGetCurrent()

var res: [Float] = []
for i in (0..<nbElements) {
    res.append(a1[i] + a2[i])
}

elapsed = CFAbsoluteTimeGetCurrent() - start
print("Elapsed with CPU: \(elapsed) with \(nbElements) elements")
