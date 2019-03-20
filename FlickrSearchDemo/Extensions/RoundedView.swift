//
//  SCRRoundedView.swift
//  FlickrSearchDemo
//
//  Created by Andrew McCalla on 3/19/19.
//  Copyright © 2019 Andrew McCalla. All rights reserved.
//

import Foundation
import UIKit

class RoundedView : UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.masksToBounds = true
        layer.cornerRadius = frame.height / 2
    }
}
