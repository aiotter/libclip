import Cocoa
import Foundation

@_cdecl("pasteAs")
public func pasteAs(dataTypeName: UnsafePointer<UInt8>, buffer: UnsafeMutableRawPointer) -> UInt64 {
    let pasteboard: NSPasteboard = .general
    let type = NSPasteboard.PasteboardType(rawValue: String.init(cString: dataTypeName))
    let data = pasteboard.data(forType: type)
    if (data != nil) {
        return UInt64(data!.copyBytes(to: UnsafeMutableRawBufferPointer.init(start: buffer, count: data!.count)))
    } else {
        return 0
    }
}

@_cdecl("getPasteSize")
public func getPasteSize(dataTypeName: UnsafePointer<UInt8>) -> UInt64 {
    let pasteboard: NSPasteboard = .general
    let type = NSPasteboard.PasteboardType(rawValue: String.init(cString: dataTypeName))
    let data = pasteboard.data(forType: type)
    if (data != nil) {
        return UInt64(data!.count)
    } else {
        return 0
    }
}

@_cdecl("getTypes")
public func getTypes(buffer: UnsafeMutableRawPointer) -> UInt32 {
    let pasteboard: NSPasteboard = .general
    let str: String = pasteboard.types?.map({ $0.rawValue }).joined(separator: "\0") ?? ""
    let count = Array(str.utf8).copyBytes(to: UnsafeMutableRawBufferPointer.init(start: buffer, count: str.count))
    return UInt32(count)
}

@_cdecl("getTypesBufferSize")
public func getTypesBufferSize() -> UInt32 {
    let pasteboard: NSPasteboard = .general
    let size = (pasteboard.types?.reduce(0, { x, y in x + y.rawValue.count }) ?? 0) + (pasteboard.types?.count ?? 1) - 1
    return UInt32(size)
}
