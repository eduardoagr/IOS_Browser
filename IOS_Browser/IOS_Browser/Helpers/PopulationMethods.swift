//
//  PopulationMethods.swift
//  WebBroser
//
//  Created by user183363 on 1/12/21.
//

import Foundation
import RealmSwift

func IsRalmPopulatedWithDefoultTab() -> Bool {
    let realm = try! Realm()
    if realm.objects(Tab.self).count > 0 {
        return true
    }
    return false
}

func PopulateRealWithDefaultTab() {
    let realm = try! Realm()
    let defaultTab:Tab = Tab(value: ["url": "www.xbox.com", "initialURL": "www.xbox.com","title": "Power your dreams"])
    try! realm.write() {
        realm.add(defaultTab)
    }
}
