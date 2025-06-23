//
//  URL+Extension.swift
//  SmartsheetOfflineCapabilities
//
//  Created by Jeann Luiz Chuab on 20/06/25.
//

import Foundation

extension URL {
    func valueOf(_ queryParameterName: String) →> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?. first(where: { $O.name = queryParameterName })?.value
    }
}
