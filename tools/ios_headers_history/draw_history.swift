//
//  main.swift
//  draw_history
//
//  Created by nst on 20/12/15.
//  Copyright © 2015 Nicolas Seriot. All rights reserved.
//

import Cocoa

let TOP_MARGIN_HEIGHT = 12
let RIGHT_MARGIN_WIDTH = 260
let ROW_HEIGHT = 12
let COL_WIDTH = 32

enum Error : ErrorType {
    case BadFormat
    case BadStatusName
}

func matches(string s: String, pattern: String) throws -> [String] {
    
    let regex = try NSRegularExpression(pattern: pattern, options: [])
    let matches = regex.matchesInString(s, options: [], range: NSMakeRange(0, s.characters.count))
    
    guard matches.count > 0 else { return [] }
    
    let textCheckingResult = matches[0]
    
    var results = [String]()
    
    for index in 1..<textCheckingResult.numberOfRanges {
        results.append((s as NSString).substringWithRange(textCheckingResult.rangeAtIndex(index)))
    }
    
    return results
}

func versionAndStatus(filename s: String) throws -> (version:String, status:String) {
    let results = try matches(string: s, pattern: "(\\d)_(\\d)_(\\S*)\\.txt")
    guard results.count == 3 else { throw Error.BadFormat }
    return (version:"\(results[0]).\(results[1])", status:results[2])
}

func readData(path path:String) throws -> ([String], [String:[String:String]]) {
    
    var d : [String:[String:String]] = [:]
    
    var versions = Set<String>()
    
    let filenames = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(path).filter{ $0.hasSuffix(".txt") }
    
    for filename in filenames {
        let (version, status) = try versionAndStatus(filename: filename)
        let filepath = (path as NSString).stringByAppendingPathComponent(filename)
        let contents = try String(contentsOfFile: filepath, encoding: NSUTF8StringEncoding)
        
        versions.insert(version)
        
        contents.enumerateLines({ (symbol, stop) -> () in
            if(d[symbol] == nil) { d[symbol] = [:] }
            d[symbol]![version] = status
        })
    }
    
    return (versions.sort(), d)
}

private func saveAsPNGWithName(fileName: String, bitmap: NSBitmapImageRep) -> Bool {
    if let data = bitmap.representationUsingType(NSBitmapImageFileType.NSPNGFileType, properties: [:]) {
        return data.writeToFile(fileName, atomically: false)
    }
    return false
}

private func color(status:String) -> NSColor {
    switch status {
    case "pub": return NSColor(calibratedRed:0.0, green: 102.0/255.0, blue:0.0, alpha:1.0)
    case "pri": return NSColor.redColor()
    case "lib": return NSColor.blueColor()
    default: return NSColor.whiteColor()
    }
}

private func drawIntoBitmap(bitmap: NSBitmapImageRep, versions: [String], data d:[String:[String:String]] ) {
    let context = NSGraphicsContext(bitmapImageRep: bitmap)
    let cgContext : CGContextRef? = context?.CGContext
    
    NSGraphicsContext.setCurrentContext(context)
    
    CGContextSaveGState(cgContext)
    
    CGContextSetAllowsAntialiasing(cgContext, false)
    
    let textAttributes : [String : AnyObject] = [
        NSFontAttributeName: NSFont(name: "Monaco", size: 10.0)!,
        NSForegroundColorAttributeName: NSColor.blackColor()
    ]
    
    let sortedSymbols = Array(d.keys).sort()
    
    NSColor.lightGrayColor().setFill()
    NSRectFill(CGRectMake(0, 0, bitmap.size.width, bitmap.size.height))
    
    for (i, s) in sortedSymbols.enumerate() {
        // draw symbols
        let x = CGFloat(versions.count * COL_WIDTH + 3)
        let y = bitmap.size.height - CGFloat(2 * TOP_MARGIN_HEIGHT + i * ROW_HEIGHT)
        s.drawAtPoint(CGPointMake(x, y), withAttributes:textAttributes)
        
        // fill boxes
        for (version, status) in d[s]! {
            color(status).setFill()
            
            let rect = CGRectMake(
                CGFloat(versions.indexOf(version)! * COL_WIDTH) + 1,
                bitmap.size.height - CGFloat(2 * TOP_MARGIN_HEIGHT + i * ROW_HEIGHT - 1),
                CGFloat(COL_WIDTH) - 1,
                CGFloat(ROW_HEIGHT - 1)
            )
            
            NSRectFill(rect)
        }
    }
    
    // draw vertical separators
    var major : String = ""
    for (i, v) in versions.enumerate() {
        let current_major : String = v.componentsSeparatedByString(".")[0]
        if current_major != major {
            let p1 = CGPointMake(CGFloat(i * COL_WIDTH), 0)
            let p2 = CGPointMake(CGFloat(i * COL_WIDTH), CGFloat(d.count * ROW_HEIGHT + TOP_MARGIN_HEIGHT))
            NSBezierPath.strokeLineFromPoint(p1, toPoint: p2)
            
            major = current_major
        }
        // draw column headers
        v.drawAtPoint(CGPointMake(CGFloat(i * COL_WIDTH + 7), bitmap.size.height - CGFloat(TOP_MARGIN_HEIGHT)), withAttributes:textAttributes)
    }
    
    let p1 = CGPointMake(CGFloat(versions.count * COL_WIDTH), bitmap.size.height)
    let p2 = CGPointMake(CGFloat(versions.count * COL_WIDTH), bitmap.size.height - CGFloat(d.count * ROW_HEIGHT + TOP_MARGIN_HEIGHT))
    NSBezierPath.strokeLineFromPoint(p1, toPoint: p2)
    
    let p3 = CGPointMake(0, bitmap.size.height - CGFloat(TOP_MARGIN_HEIGHT))
    let p4 = CGPointMake(CGFloat(versions.count * COL_WIDTH), bitmap.size.height - CGFloat(TOP_MARGIN_HEIGHT))
    NSBezierPath.strokeLineFromPoint(p3, toPoint: p4)
    
    CGContextRestoreGState(cgContext)
}

public func main() -> Int {
    
    guard Process.arguments.count == 2 else {
        print("Usage: $ swift draw_history.swift path/to/data")
        return 1
    }
    
    let versions : [String]
    let d : [String:[String:String]]
    
    do {
        (versions, d) = try readData(path:Process.arguments[1])
    } catch {
        print(error)
        return 1
    }
    
    let WIDTH = CGFloat(versions.count * COL_WIDTH + RIGHT_MARGIN_WIDTH)
    let HEIGHT = CGFloat(d.count * ROW_HEIGHT + TOP_MARGIN_HEIGHT)
    let SIZE = CGSize(width: WIDTH, height: HEIGHT)
    
    let optBitmapImageRep = NSBitmapImageRep(
        bitmapDataPlanes:nil,
        pixelsWide:Int(SIZE.width),
        pixelsHigh:Int(SIZE.height),
        bitsPerSample:8,
        samplesPerPixel:4,
        hasAlpha:true,
        isPlanar:false,
        colorSpaceName:NSDeviceRGBColorSpace,
        bytesPerRow:0,
        bitsPerPixel:0
    )
    
    guard let bitmap = optBitmapImageRep else { fatalError("can't create bitmap image rep") }
    
    drawIntoBitmap(bitmap, versions: versions, data:d)
    
    let currentPath : NSString = NSFileManager.defaultManager().currentDirectoryPath
    let outPath = currentPath.stringByAppendingPathComponent("ios_frameworks.png")
    let success = saveAsPNGWithName(outPath, bitmap:bitmap)
    
    if(success) {
        print("PNG written at", outPath)
    } else {
        print("cannot write PNG at", outPath)
    }
    
    return success ? 0 : 1
}

main()
