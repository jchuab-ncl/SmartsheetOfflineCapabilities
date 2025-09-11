//
//  ServerInfo.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 09/09/25.
//

import Foundation
import SwiftData

@Model
final class CachedServerInfoDTO {
    var formats: CachedServerInfoFormatsDTO
    
    init(formats: CachedServerInfoFormatsDTO) {
        self.formats = formats
    }
    
    init(dto: ServerInfoDTO) {
        self.formats = .init(dto: dto.formats)
    }
    
    func toDTO() -> ServerInfoDTO {
        return ServerInfoDTO(formats: formats.toDTO())
    }
}

@Model
final class CachedServerInfoFormatsDTO {
    var defaults: String
    var bold: [String]
    var color: [String]
    var currency: [CachedCurrency]
    var dateFormat: [String]
    var decimalCount: [String]
    var fontFamily: [CachedFontFamily]
    var fontSize: [String]
    var horizontalAlign: [String]
    var italic: [String]
    var numberFormat: [String]
    var strikethrough: [String]
    var textWrap: [String]
    var thousandsSeparator: [String]
    var underline: [String]
    var verticalAlign: [String]
    
    init(
         defaults: String,
         bold: [String],
         color: [String],
         currency: [CachedCurrency],
         dateFormat: [String],
         decimalCount: [String],
         fontFamily: [CachedFontFamily],
         fontSize: [String],
         horizontalAlign: [String],
         italic: [String],
         numberFormat: [String],
         strikethrough: [String],
         textWrap: [String],
         thousandsSeparator: [String],
         underline: [String],
         verticalAlign: [String]
    ) {
        self.defaults = defaults
        self.bold = bold
        self.color = color
        self.currency = currency
        self.dateFormat = dateFormat
        self.decimalCount = decimalCount
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.horizontalAlign = horizontalAlign
        self.italic = italic
        self.numberFormat = numberFormat
        self.strikethrough = strikethrough
        self.textWrap = textWrap
        self.thousandsSeparator = thousandsSeparator
        self.underline = underline
        self.verticalAlign = verticalAlign
    }
    
    convenience init(dto: ServerInfoFormatsDTO) {
        self.init(
            defaults: dto.defaults,
            bold: dto.bold,
            color: dto.color,
            currency: dto.currency.map { CachedCurrency(dto: $0) },
            dateFormat: dto.dateFormat,
            decimalCount: dto.decimalCount,
            fontFamily: dto.fontFamily.map { CachedFontFamily(dto: $0) },
            fontSize: dto.fontSize,
            horizontalAlign: dto.horizontalAlign,
            italic: dto.italic,
            numberFormat: dto.numberFormat,
            strikethrough: dto.strikethrough,
            textWrap: dto.textWrap,
            thousandsSeparator: dto.thousandsSeparator,
            underline: dto.underline,
            verticalAlign: dto.verticalAlign
        )
    }
    
    func toDTO() -> ServerInfoFormatsDTO {
        ServerInfoFormatsDTO(
            defaults: defaults,
            bold: bold,
            color: color,
            currency: currency.map { $0.toDTO() },
            dateFormat: dateFormat,
            decimalCount: decimalCount,
            fontFamily: fontFamily.map { $0.toDTO() },
            fontSize: fontSize,
            horizontalAlign: horizontalAlign,
            italic: italic,
            numberFormat: numberFormat,
            strikethrough: strikethrough,
            textWrap: textWrap,
            thousandsSeparator: thousandsSeparator,
            underline: underline,
            verticalAlign: verticalAlign
        )
    }
    
    static var empty: ServerInfoFormatsDTO {
        return .init(
            defaults: "",
            bold: [],
            color: [],
            currency: [],
            dateFormat: [],
            decimalCount: [],
            fontFamily: [],
            fontSize: [],
            horizontalAlign: [],
            italic: [],
            numberFormat: [],
            strikethrough: [],
            textWrap: [],
            thousandsSeparator: [],
            underline: [],
            verticalAlign: []
        )
    }
}

@Model
final class CachedCurrency {
    @Attribute(.unique) var code: String
    var symbol: String
    
    init(code: String, symbol: String) {
        self.code = code
        self.symbol = symbol
    }
    
    convenience init(dto: ServerInfoFormatsDTO.CurrencyDTO) {
        self.init(code: dto.code, symbol: dto.symbol)
    }
    
    func toDTO() -> ServerInfoFormatsDTO.CurrencyDTO {
        ServerInfoFormatsDTO.CurrencyDTO(code: code, symbol: symbol)
    }
}

@Model
final class CachedFontFamily {
    @Attribute(.unique) var name: String
    var displayName: String
    
    init(name: String, displayName: String) {
        self.name = name
        self.displayName = displayName
    }
    
    convenience init(dto: ServerInfoFormatsDTO.FontFamilyDTO) {
        self.init(name: dto.name, displayName: dto.displayName ?? "")
    }
    
    func toDTO() -> ServerInfoFormatsDTO.FontFamilyDTO {
        ServerInfoFormatsDTO.FontFamilyDTO(name: name, displayName: displayName)
    }
}

// MARK: - Codable DTOs (Network)

public struct ServerInfoDTO: Codable, Hashable, Sendable {
    let formats: ServerInfoFormatsDTO
    
    static let empty: ServerInfoDTO = .init(formats: .empty)
}

public struct ServerInfoFormatsDTO: Codable, Hashable, Sendable {
    struct CurrencyDTO: Codable, Hashable, Sendable {
        let code: String
        let symbol: String
    }
    struct FontFamilyDTO: Codable, Hashable, Sendable {
        let name: String
        let displayName: String?
    }
    
    let defaults: String
    let bold: [String]
    let color: [String]
    let currency: [CurrencyDTO]
    let dateFormat: [String]
    let decimalCount: [String]
    let fontFamily: [FontFamilyDTO]
    let fontSize: [String]
    let horizontalAlign: [String]
    let italic: [String]
    let numberFormat: [String]
    let strikethrough: [String]
    let textWrap: [String]
    let thousandsSeparator: [String]
    let underline: [String]
    let verticalAlign: [String]
    
    static var empty: ServerInfoFormatsDTO {
        return .init(
            defaults: "",
            bold: [],
            color: [],
            currency: [],
            dateFormat: [],
            decimalCount: [],
            fontFamily: [],
            fontSize: [],
            horizontalAlign: [],
            italic: [],
            numberFormat: [],
            strikethrough: [],
            textWrap: [],
            thousandsSeparator: [],
            underline: [],
            verticalAlign: []
        )            
    }
}
