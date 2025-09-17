//
//  ServerInfoFormatParser.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 11/09/25.
//

import Combine
import Foundation
import SwiftUI

// MARK: - Enums for properties

//public enum HorizontalAlign: String {
//    case `default`
//    case left
//    case center
//    case right
//}

public enum VerticalAlign: String {
    case `default`
    case top
    case middle
    case bottom
}

public enum NumberFormat: String {
    case none
    case number
    case currency
    case percent
}

public struct ParsedFormat {
    public let fontFamily: String?
    public let fontSize: Int?
    public let bold: Bool
    public let italic: Bool
    public let underline: Bool
    public let strikethrough: Bool
    public let horizontalAlign: TextAlignment
    public let verticalAlign: VerticalAlign
    public let textColor: Color
    public let backgroundColor: Color
    public let taskbarColor: String?
    public let currency: String?
    public let decimalCount: Int?
    public let thousandsSeparator: Bool
    public let numberFormat: NumberFormat
    public let textWrap: Bool
    public let dateFormat: String?
    
    public static let empty: ParsedFormat = .init(
        fontFamily: nil,
        fontSize: nil,
        bold: false,
        italic: false,
        underline: false,
        strikethrough: false,
        horizontalAlign: .center,
        verticalAlign: .default,
        textColor: .black,
        backgroundColor: .clear,
        taskbarColor: nil,
        currency: nil,
        decimalCount: nil,
        thousandsSeparator: false,
        numberFormat: .none,
        textWrap: false,
        dateFormat: nil
    )
}

// MARK: - Parser

//TODO: Add this as depency

public protocol ServerInfoFormatParserProtocol {
    /// Parses a format string and returns a ParsedFormat object.
    func parse(formatString: String) -> ParsedFormat
}

public final class ServerInfoFormatParserService: ServerInfoFormatParserProtocol {
    private var serverInfo: ServerInfoDTO = .empty
    private let sheetService: SheetServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    //TODO: Add docs
    
    public init(
        sheetService: SheetServiceProtocol = Dependencies.shared.sheetService
    ) {
        self.sheetService = sheetService
        
        sheetService.serverInfoDTOMemoryRepo
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] result in
                self?.serverInfo = result
            })
            .store(in: &cancellables)
    }

    public func parse(formatString: String) -> ParsedFormat {
        let parts = formatString.split(separator: ",", omittingEmptySubsequences: false)
        // Safe lookup helper
        func indexValue(at pos: Int) -> Int? {
            guard pos < parts.count, let val = Int(String(parts[pos])) else { return nil }
            return val
        }

        // 0: fontFamily
        let fontFamilyIndex = indexValue(at: 0)
        let fontFamily: String?
        if let idx = fontFamilyIndex {
            if idx < serverInfo.formats.fontFamily.count {
                fontFamily = serverInfo.formats.fontFamily[idx].name
            } else {
                fontFamily = nil
            }
        } else {
            fontFamily = nil
        }

        // 1: fontSize
        let fontSizeIndex = indexValue(at: 1)
        let fontSize: Int?
        if let idx = fontSizeIndex {
            if idx < serverInfo.formats.fontSize.count {
                fontSize = Int(serverInfo.formats.fontSize[idx])
            } else {
                fontSize = nil
            }
        } else {
            fontSize = nil
        }

        // 2: bold
        let bold = indexValue(at: 2).map { $0 == 1 } ?? false

        // 3: italic
        let italic = indexValue(at: 3).map { $0 == 1 } ?? false

        // 4: underline
        let underline = indexValue(at: 4).map { $0 == 1 } ?? false

        // 5: strikethrough
        let strikethrough = indexValue(at: 5).map { $0 == 1 } ?? false

        // 6: horizontalAlign
        let horizontalAlignIndex = indexValue(at: 6) ?? 0
        
        var horizontalAlign: TextAlignment = .center
        
        switch serverInfo.formats.horizontalAlign[horizontalAlignIndex] {
        case "default", "left":
            horizontalAlign = .leading
        case "center":
            horizontalAlign = .center
        case "right":
            horizontalAlign = .trailing
        default:
            horizontalAlign = .center
        }        

        // 7: verticalAlign
        let verticalAlignIndex = indexValue(at: 7) ?? 0
        let verticalAlign = VerticalAlign(rawValue: serverInfo.formats.verticalAlign[verticalAlignIndex]) ?? .default

        // 8: text color
        let textColorIndex = indexValue(at: 8)
        let textColor: String
        if let idx = textColorIndex {
            if idx < serverInfo.formats.color.count {
                textColor = serverInfo.formats.color[idx]
            } else {
                textColor = Color.black.hexString
            }
        } else {
            textColor = Color.black.hexString
        }

        // 9: background color
        let backgroundColorIndex = indexValue(at: 9)
        let backgroundColor: String
        if let idx = backgroundColorIndex {
            if idx < serverInfo.formats.color.count {
                backgroundColor = serverInfo.formats.color[idx]
            } else {
                backgroundColor = Color.white.hexString
            }
        } else {
            backgroundColor = Color.white.hexString
        }

        // 10: taskbar color
        let taskbarColorIndex = indexValue(at: 10)
        let taskbarColor: String?
        if let idx = taskbarColorIndex {
            if idx < serverInfo.formats.color.count {
                taskbarColor = serverInfo.formats.color[idx]
            } else {
                taskbarColor = nil
            }
        } else {
            taskbarColor = nil
        }

        // 11: currency
        let currencyIndex = indexValue(at: 11)
        let currency: String?
        if let idx = currencyIndex {
            if idx < serverInfo.formats.currency.count {
                currency = serverInfo.formats.currency[idx].code
            } else {
                currency = nil
            }
        } else {
            currency = nil
        }

        // 12: decimalCount
        let decimalCountIndex = indexValue(at: 12)
        let decimalCount: Int?
        if let idx = decimalCountIndex {
            if idx < serverInfo.formats.decimalCount.count {
                decimalCount = Int(serverInfo.formats.decimalCount[idx])
            } else {
                decimalCount = nil
            }
        } else {
            decimalCount = nil
        }

        // 13: thousandsSeparator
        let thousandsSeparator = indexValue(at: 13).map { $0 == 1 } ?? false

        // 14: numberFormat
        let numberFormatIndex = indexValue(at: 14) ?? 0
        let nfRaw = serverInfo.formats.numberFormat[numberFormatIndex].lowercased()
        let numberFormat = NumberFormat(rawValue: nfRaw) ?? .none

        // 15: textWrap
        let textWrap = indexValue(at: 15).map { $0 == 1 } ?? false

        // 16: dateFormat
        let dateFormatIndex = indexValue(at: 16)
        let dateFormat: String?
        if let idx = dateFormatIndex {
            if idx < serverInfo.formats.dateFormat.count {
                dateFormat = serverInfo.formats.dateFormat[idx]
            } else {
                dateFormat = nil
            }
        } else {
            dateFormat = nil
        }

        return ParsedFormat(
            fontFamily: fontFamily,
            fontSize: fontSize,
            bold: bold,
            italic: italic,
            underline: underline,
            strikethrough: strikethrough,
            horizontalAlign: horizontalAlign,
            verticalAlign: verticalAlign,
            textColor: Color(hex: textColor),
            backgroundColor: Color(hex: backgroundColor),
            taskbarColor: taskbarColor,
            currency: currency,
            decimalCount: decimalCount,
            thousandsSeparator: thousandsSeparator,
            numberFormat: numberFormat,
            textWrap: textWrap,
            dateFormat: dateFormat
        )
    }
}
