#!/usr/bin/env swift
// Square center-crop an animated GIF and scale it to 128x128, preserving frames and delays.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let target: CGFloat = 128

guard CommandLine.arguments.count == 3 else {
  FileHandle.standardError.write(Data("Expected input and output paths\n".utf8))
  exit(1)
}

let inURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let source = CGImageSourceCreateWithURL(inURL as CFURL, nil), CGImageSourceGetCount(source) > 0 else {
  FileHandle.standardError.write(Data("Could not read GIF\n".utf8))
  exit(2)
}

let frameCount = CGImageSourceGetCount(source)
guard let destination = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.gif.identifier as CFString, frameCount, nil) else {
  FileHandle.standardError.write(Data("Could not create output GIF\n".utf8))
  exit(3)
}

if
  let sourceProperties = CGImageSourceCopyProperties(source, nil) as? [CFString: Any],
  let sourceGifProperties = sourceProperties[kCGImagePropertyGIFDictionary] as? [CFString: Any],
  let loopCount = sourceGifProperties[kCGImagePropertyGIFLoopCount]
{
  CGImageDestinationSetProperties(destination, [
    kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: loopCount]
  ] as CFDictionary)
}

for frameIndex in 0..<frameCount {
  guard let frame = CGImageSourceCreateImageAtIndex(source, frameIndex, nil) else { continue }

  let width = CGFloat(frame.width)
  let height = CGFloat(frame.height)
  let square = min(width, height)
  let scale = target / square
  let cropX = (width - square) / 2
  let cropY = (height - square) / 2

  guard
    let context = CGContext(
      data: nil,
      width: Int(target),
      height: Int(target),
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
  else { continue }

  context.interpolationQuality = .high
  context.clear(CGRect(x: 0, y: 0, width: target, height: target))
  context.draw(frame, in: CGRect(x: -cropX * scale, y: -cropY * scale, width: width * scale, height: height * scale))

  guard let resized = context.makeImage() else { continue }

  var frameGifProperties: [CFString: Any] = [:]
  if
    let frameProperties = CGImageSourceCopyPropertiesAtIndex(source, frameIndex, nil) as? [CFString: Any],
    let sourceGifProperties = frameProperties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
  {
    if let delay = sourceGifProperties[kCGImagePropertyGIFUnclampedDelayTime] {
      frameGifProperties[kCGImagePropertyGIFUnclampedDelayTime] = delay
    }
    if let delay = sourceGifProperties[kCGImagePropertyGIFDelayTime] {
      frameGifProperties[kCGImagePropertyGIFDelayTime] = delay
    }
  }

  CGImageDestinationAddImage(destination, resized, [
    kCGImagePropertyGIFDictionary: frameGifProperties
  ] as CFDictionary)
}

guard CGImageDestinationFinalize(destination) else {
  FileHandle.standardError.write(Data("Could not write output GIF\n".utf8))
  exit(4)
}
