//
//  FlickrPicture.swift
//  FlickrSearchDemo
//
//  Created by Drew McCalla on 3/20/19.
//  Copyright © 2019 Andrew McCalla. All rights reserved.
//

import Foundation

class FlickrPicture {
    var pictureUrl: String?
    var title: String?
    
    init(pictureUrl: String?, title: String?) {
        self.pictureUrl = pictureUrl
        self.title = title
    }
}
