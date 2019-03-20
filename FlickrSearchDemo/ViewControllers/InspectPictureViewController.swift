//
//  InspectPictureViewController.swift
//  FlickrSearchDemo
//
//  Created by Andrew McCalla on 3/19/19.
//  Copyright © 2019 Andrew McCalla. All rights reserved.
//

import UIKit

class InspectPictureViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pictureImageView: UIImageView!
    
    var pictureUrl = ""
    var titleLabelText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pictureImageView.sd_setImage(with: URL(string: pictureUrl), placeholderImage: UIImage())
        titleLabel.text = titleLabelText
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
