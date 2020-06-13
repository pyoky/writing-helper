//
//  main.swift
//  Onelook Search
//
//  Created by Pyokyeong Son on 2020/06/11.
//  Copyright © 2020 Pyokyeong Son. All rights reserved.
//

import Foundation

var s = DispatchSemaphore(value: 0)

#warning("Don't forget the Sephamore")

let search = Search()

search.related(.follows, "wreak")
search.maxResults(10)


search.search() { data in
    for d in data! { print(d.word) }
    s.signal()
}

//print(OneLook.urlConstructor(options: [.soundLike : ["sea"]]))

s.wait()
