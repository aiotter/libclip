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

@_cdecl("clearBoard")
public func clearBoard() -> Void {
    let pasteboard: NSPasteboard = .general
    pasteboard.clearContents()
}

@_cdecl("createItem")
public func createItem() -> UnsafeMutablePointer<NSPasteboardItem>? {
    let item = NSPasteboardItem()
    let pointer = UnsafeMutablePointer<NSPasteboardItem>.allocate(capacity: 1)
    pointer.initialize(to: item)
    return pointer
}

@_cdecl("setData")
public func setData(itemPointer: UnsafePointer<NSPasteboardItem>, dataTypeName: UnsafePointer<UInt8>, buffer: UnsafeRawPointer, size: UInt32) -> UInt8 {
    let type = NSPasteboard.PasteboardType(rawValue: String.init(cString: dataTypeName))
    let data = Data.init(bytes: buffer, count: Int(size))
    let result = itemPointer.pointee.setData(data, forType: type)
    return result ? 0 : 1
}

@_cdecl("copy")
public func copy(itemsPointer: UnsafePointer<UnsafePointer<NSPasteboardItem>>, count: UInt8) -> UInt8 {
    let pasteboard: NSPasteboard = .general
    var items: [NSPasteboardItem] = []

    for i in 0..<Int(count) {
        items.append(itemsPointer.advanced(by: i).pointee.pointee)
    }

    let result = pasteboard.writeObjects(items)
    return result ? 0 : 1
}

@_cdecl("setAs")
public func setAs(dataTypeName: UnsafePointer<UInt8>, buffer: UnsafeRawPointer, size: UInt32) -> UInt8 {
    let pasteboard: NSPasteboard = .general
    let type = NSPasteboard.PasteboardType(rawValue: String.init(cString: dataTypeName))
    let data = Data.init(bytes: buffer, count: Int(size))

    if (pasteboard.setData(data, forType: type)) {
        return 0
    } else {
        return 1
    }
}

@_cdecl("destroyItem")
public func destroyItem(pointer: UnsafePointer<NSPasteboardItem>?) -> Void {
    if (pointer != nil) {
        pointer!.deallocate()
    }
}
