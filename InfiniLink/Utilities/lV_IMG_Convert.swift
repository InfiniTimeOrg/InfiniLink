//
//  lv_img_conv.swift
//  InfiniSync
//
//  Created by Jen on 2/17/24.
//

import Foundation
import CoreGraphics

enum ColorFormat {
    case CF_INDEXED_1_BIT, CF_TRUE_COLOR_ALPHA
}

enum BinaryFormat {
    case ARGB8565_RBSWAP, ARGB8888
}

func testClassifyPixel() {
    // test difference between round() and round_half_up()
    print("First Classify Pixel Test \(classifyPixel(value: 18, bits: 5) == 16 ? "Passed!" : "Failed!")")
    // school rounding 4.5 to 5, but banker's rounding 4.5 to 4
    print("Second Classify Pixel Test \(classifyPixel(value: 18, bits: 6) == 20 ? "Passed!" : "Failed!")")
}

func classifyPixel(value: Double, bits: Int) -> Int {
    func roundHalfUp(v: Double) -> Int {
        return Int(round(v))
    }
    let tmp = Double(1 << (8 - bits))
    var val = Double(roundHalfUp(v: value / tmp)) * tmp
    if val < 0 {
        val = 0
    }
    return Int(val)
}

// only implemented the bare minimum, everything else is not implemented
func lvImageConvert(img: CGImage, colorFormat: ColorFormat = .CF_TRUE_COLOR_ALPHA, binaryFormat: BinaryFormat = .ARGB8565_RBSWAP, fade: Bool = false) -> Data? {
    print("Beginning conversion of image.")

    var fileImg = img
    let imgHeight = img.height
    let imgWidth = img.width
    
    if colorFormat == .CF_TRUE_COLOR_ALPHA && fileImg.alphaInfo != .last && fileImg.alphaInfo != .premultipliedLast {
        // Convert image to RGBA
        let rgba = CGContext(data: nil, width: imgWidth, height: imgHeight, bitsPerComponent: 8, bytesPerRow: imgWidth * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        rgba?.draw(fileImg, in: CGRect(x: 0, y: 0, width: imgWidth, height: imgHeight))
        if let cgimg = rgba?.makeImage() {
            fileImg = cgimg
        }
    } else if colorFormat == .CF_INDEXED_1_BIT && fileImg.colorSpace?.model != .monochrome {
        // Convert image to grayscale
        let gray = CGContext(data: nil, width: imgWidth, height: imgHeight, bitsPerComponent: 8, bytesPerRow: imgWidth, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        gray?.draw(fileImg, in: CGRect(x: 0, y: 0, width: imgWidth, height: imgHeight))
        if let cgimg = gray?.makeImage() {
            fileImg = cgimg
        }
    }

    var buf : [UInt8] = []
    if colorFormat == .CF_TRUE_COLOR_ALPHA && binaryFormat == .ARGB8888  {
        buf = [UInt8](repeating: 0, count: imgHeight*imgWidth*4) // 4 bytes (24 bit) per pixel
        for y in 0..<imgHeight {
            for x in 0..<imgWidth {
                let i = (y*imgWidth + x)*4 // buffer-index
                let pixel = fileImg.getPixel(x: x, y: y, fade: fade, height: imgHeight)
                let r = pixel!.red
                let g = pixel!.green
                let b = pixel!.blue
                let a = pixel!.alpha
                buf[i + 0] = r
                buf[i + 1] = g
                buf[i + 2] = b
                buf[i + 3] = a
            }
        }
    } else if colorFormat == .CF_TRUE_COLOR_ALPHA && binaryFormat == .ARGB8565_RBSWAP  {
        buf = [UInt8](repeating: 0, count: imgHeight*imgWidth*3) // 3 bytes (24 bit) per pixel
        for y in 0..<imgHeight {
            for x in 0..<imgWidth {
                let i = (y*imgWidth + x)*3 // buffer-index
                let pixel = fileImg.getPixel(x: x, y: y, fade: fade, height: imgHeight)
                var r_act = classifyPixel(value: Double(pixel!.red), bits: 5)
                var g_act = classifyPixel(value: Double(pixel!.green), bits: 6)
                var b_act = classifyPixel(value: Double(pixel!.blue), bits: 5)
                let a = pixel!.alpha
                r_act = min(r_act, 0xF8)
                g_act = min(g_act, 0xFC)
                b_act = min(b_act, 0xF8)
                let c16 = (r_act << 8) | (g_act << 3) | (b_act >> 3) // RGR565
                buf[i + 0] = UInt8((c16 >> 8) & 0xFF)
                buf[i + 1] = UInt8(c16 & 0xFF)
                buf[i + 2] = a
            }
        }
    } else if colorFormat == .CF_INDEXED_1_BIT {
        var w = imgWidth >> 3
        if imgWidth & 0x07 != 0 {
            w += 1
        }
        let max_p = w * (imgHeight - 1) + ((imgWidth - 1) >> 3) + 8  // +8 for the palette
        buf = [UInt8](repeating: 0, count: max_p+1)

        for y in 0..<imgHeight {
            for x in 0..<imgWidth {
                let pixel = fileImg.getPixel(x: x, y: y, fade: fade, height: imgHeight)!
                let c = (pixel.red + pixel.blue + pixel.green) / 255
                let p = w * y + (x >> 3) + 8  // +8 for the palette
                buf[p] |= (c & 0x1) << (7 - (x & 0x7))
            }
        }

        // Write palette information (for indexed-1-bit, we need a palette with two values)
        // Write 8 palette bytes
        buf[0] = 0
        buf[1] = 0
        buf[2] = 0
        buf[3] = 0
        // Normally there is more math behind this, but for the current use case, this is close enough
        // Only needs to be more complicated if we have more than 2 colors in the palette
        buf[4] = 255
        buf[5] = 255
        buf[6] = 255
        buf[7] = 255

    }

    var lv_cf : UInt32
    switch colorFormat {
    case .CF_TRUE_COLOR_ALPHA:
        lv_cf = 5
    case .CF_INDEXED_1_BIT:
        lv_cf = 7
    }
    
    let header_32bit: UInt32 = lv_cf | (UInt32(imgWidth << 10)) | (UInt32(imgHeight << 21))
    print("header_32bit: \(header_32bit)")
    
    var buf_out = Data(count: 4 + buf.count)
    buf_out[0] = UInt8(header_32bit & 0x000000FF)
    buf_out[1] = UInt8((header_32bit & 0x0000FF00) >> 8)
    buf_out[2] = UInt8((header_32bit & 0x00FF0000) >> 16)
    buf_out[3] = UInt8((header_32bit & 0xFF000000) >> 24)
    buf_out[4...] = Data(buf)
    
    return buf_out
}

extension CGImage {
    func getPixel(x: Int, y: Int, fade: Bool, height: Int) -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8)? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        var pixelData: [UInt8] = [0, 0, 0, 0]

        guard let context = CGContext(data: &pixelData,
                                      width: 1,
                                      height: 1,
                                      bitsPerComponent: 8,
                                      bytesPerRow: 4,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo),
              let cgImage = self.cropping(to: CGRect(x: x, y: y, width: 1, height: 1)) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        let add = Double(height) * 0.25
        let div = Double(height) * 0.65

        let red = fade ? UInt8(Double(pixelData[0]) * ((Double(y) + add) / div).clamped(to: 0...1)) : pixelData[0]
        let green = fade ? UInt8(Double(pixelData[1]) * ((Double(y) + add) / div).clamped(to: 0...1)) : pixelData[1]
        let blue = fade ? UInt8(Double(pixelData[2]) * ((Double(y) + add) / div).clamped(to: 0...1)) : pixelData[2]
        let alpha = pixelData[3]

        return (red, green, blue, alpha)
    }
}

extension Strideable where Stride: SignedInteger {
    func clamped(to limits: CountableClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
