//
//  File.swift
//  Swiftlog
//
//  Created by Jaden Geller on 1/19/16.
//  Copyright © 2016 Jaden Geller. All rights reserved.
//

import Darwin

public class Stream {
    private let file: UnsafeMutablePointer<FILE>
    
    private init(file: UnsafeMutablePointer<FILE>) {
        self.file = file
    }
}

public class MutableStream: Stream {
    
}

public final class FileStream: Stream {
    public init?(_ filename: String) {
        super.init(file: fopen(filename, "r"))
        guard self.file != nil else { return nil }
    }
    
    deinit {
        fclose(file)
    }
}

public final class InputStream: Stream {
    public init() {
        super.init(file: stdin)
    }
}

extension Stream: SequenceType, GeneratorType {
    // NOTE THAT STDIN IS LINE BUFFERED
    // SO WE CAN'T JUSE GET A SINGLE CHAR
    public func next() -> Character? {
        let c = fgetc(file)
        guard c != EOF else { return nil }
        return Character(UnicodeScalar(unsafeBitCast(c, UInt32.self)))
    }
}

extension Stream {
    func getLine() -> String? {
        var line = ""
        while let c = next() {
            guard c != "\n" else { return line }
            line.append(c)
        }
        return nil
    }
}
