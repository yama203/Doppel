#!/usr/bin/env swift
import Cocoa

// Generate a simple app icon programmatically
let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()

let rect = NSRect(x: 0, y: 0, width: size, height: size)

// Background: rounded rectangle with gradient
let path = NSBezierPath(roundedRect: rect.insetBy(dx: 80, dy: 80), xRadius: 180, yRadius: 180)

// Gradient background (dark blue to teal)
let gradient = NSGradient(colors: [
    NSColor(red: 0.1, green: 0.15, blue: 0.35, alpha: 1.0),
    NSColor(red: 0.1, green: 0.3, blue: 0.45, alpha: 1.0)
])!
gradient.draw(in: path, angle: -45)

// Draw two disk icons (source → destination)
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 280, weight: .light),
    .foregroundColor: NSColor.white
]

// Left disk
let diskStr = NSAttributedString(string: "\u{2B82}", attributes: attrs)  // ⮂
// Use SF-like arrow instead
let arrowAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 160, weight: .bold),
    .foregroundColor: NSColor(red: 0.3, green: 0.85, blue: 0.75, alpha: 1.0)
]

// Draw two overlapping rounded rects to represent disks
let diskColor1 = NSColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 0.9)
let diskColor2 = NSColor(red: 0.3, green: 0.85, blue: 0.75, alpha: 0.9)

// Source disk (top-left)
let disk1 = NSBezierPath(roundedRect: NSRect(x: 200, y: 420, width: 280, height: 200), xRadius: 20, yRadius: 20)
diskColor1.setFill()
disk1.fill()

// Small line inside disk1
NSColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 1.0).setFill()
NSBezierPath(rect: NSRect(x: 230, y: 560, width: 120, height: 20)).fill()
NSBezierPath(rect: NSRect(x: 230, y: 520, width: 180, height: 20)).fill()
NSBezierPath(rect: NSRect(x: 230, y: 480, width: 80, height: 20)).fill()

// Arrow
let arrow = NSAttributedString(string: "→", attributes: arrowAttrs)
let arrowSize = arrow.size()
arrow.draw(at: NSPoint(x: (CGFloat(size) - arrowSize.width) / 2 + 10, y: (CGFloat(size) - arrowSize.height) / 2 - 20))

// Destination disk (bottom-right)
let disk2 = NSBezierPath(roundedRect: NSRect(x: 540, y: 370, width: 280, height: 200), xRadius: 20, yRadius: 20)
diskColor2.setFill()
disk2.fill()

// Small line inside disk2
NSColor(red: 0.15, green: 0.55, blue: 0.5, alpha: 1.0).setFill()
NSBezierPath(rect: NSRect(x: 570, y: 510, width: 120, height: 20)).fill()
NSBezierPath(rect: NSRect(x: 570, y: 470, width: 180, height: 20)).fill()
NSBezierPath(rect: NSRect(x: 570, y: 430, width: 80, height: 20)).fill()

image.unlockFocus()

// Save as PNG
guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to generate image")
    exit(1)
}

let outputPath = "Resources/AppIcon.png"
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("Icon saved to \(outputPath)")

// Generate .iconset and .icns
let iconsetPath = "Resources/AppIcon.iconset"
let fm = FileManager.default
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes = [16, 32, 128, 256, 512]
for s in sizes {
    let resized = NSImage(size: NSSize(width: s, height: s))
    resized.lockFocus()
    image.draw(in: NSRect(x: 0, y: 0, width: s, height: s))
    resized.unlockFocus()

    if let tiff = resized.tiffRepresentation,
       let bmp = NSBitmapImageRep(data: tiff),
       let png = bmp.representation(using: .png, properties: [:]) {
        try! png.write(to: URL(fileURLWithPath: "\(iconsetPath)/icon_\(s)x\(s).png"))

        // @2x version
        let s2x = s * 2
        if s2x <= 1024 {
            let resized2x = NSImage(size: NSSize(width: s2x, height: s2x))
            resized2x.lockFocus()
            image.draw(in: NSRect(x: 0, y: 0, width: s2x, height: s2x))
            resized2x.unlockFocus()
            if let tiff2 = resized2x.tiffRepresentation,
               let bmp2 = NSBitmapImageRep(data: tiff2),
               let png2 = bmp2.representation(using: .png, properties: [:]) {
                try! png2.write(to: URL(fileURLWithPath: "\(iconsetPath)/icon_\(s)x\(s)@2x.png"))
            }
        }
    }
}

// Convert to icns
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetPath, "-o", "Resources/AppIcon.icns"]
try! task.run()
task.waitUntilExit()

if task.terminationStatus == 0 {
    print("AppIcon.icns created successfully")
    try? fm.removeItem(atPath: iconsetPath)
} else {
    print("Failed to create icns")
}
