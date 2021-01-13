//
//  Tab.swift
//  WebBroser
//
//  Created by user183363 on 1/12/21.
//

import Foundation
import RealmSwift

class Tab: Object {
     @objc dynamic var url:String = ""
     @objc dynamic var initialURL:String = ""
     @objc dynamic var title:String = ""
    
    var TabDescripton:String {
        
        let urlDescription = "URL: \(url)\n"
        let initialURLDescription = "Initial URL: \(initialURL)\n"
        let titleDescription = "Title: \(title)\n"
        
        return "Tab Info:\n\(urlDescription)\(initialURLDescription)\(titleDescription)"
    }
}
