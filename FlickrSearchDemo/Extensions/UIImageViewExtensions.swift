//
//  UIImageView+SRCExtensions.swift
//  FlickrSearchDemo
//
//  Created by Andrew McCalla on 3/19/19.
//  Copyright © 2019 Andrew McCalla. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

//Provides way to download & cache images via ImageViews asynchronously
//

extension UIImageView {
    @nonobjc func setImageAndShowLoading(with urlString: String?, usingActivityIndicatorStyle style: UIActivityIndicatorView.Style = .gray) {
        if let url = URL(string: urlString ?? "") {
            setImageAndShowLoading(with: url)
        } else {
            image = nil
        }
    }
    
    @nonobjc func setImageAndShowLoading(with url : URL?, usingActivityIndicatorStyle style: UIActivityIndicatorView.Style = .gray) {
        if let url = url {
            setImageAndShowLoading(with: url)
        } else {
            image = nil
        }
    }    
}
