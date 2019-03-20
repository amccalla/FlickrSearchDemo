//
//  SCRRoundedImageView.swift
//  FlickrSearchDemo
//
//  Created by Andrew McCalla on 3/19/19.
//  Copyright © 2019 Andrew McCalla. All rights reserved.
//

import UIKit

class RoundedImageView: UIImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.masksToBounds = true
        alpha = 1.0
        layer.cornerRadius = frame.height / 2
    }
}
