//
//  SearchPicturesViewController.swift
//  FlickrSearchDemo
//
//  Created by Andrew McCalla on 3/19/19.
//  Copyright © 2019 Andrew McCalla. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SDWebImage
import SVProgressHUD

class SearchPicturesViewController: UIViewController {

    @IBOutlet weak var pictureResultsTableView: UITableView!
    @IBOutlet weak var pictureSearchBar: UISearchBar!
    
    var reachedEndOfPictures : Bool {
        if totalPages <= 1 {
            return true
        } else {
            return totalPages <= pageNumber
        }
    }
    
    var storedSearchTerms = UserDefaults.standard.value(forKey: "storedSearchTerms") as? [String]
    var filterText = ""
    var currentlyRequestingPictures = false
    var pageNumber = 1
    var totalPages = 0
    var pictureResults = [FlickrPicture]()
    var selectedPicture : FlickrPicture?
    var searchTextTimer = Timer()
    var userTappedDone = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationVC = segue.destination as? InspectPictureViewController, let pictureUrl = selectedPicture?.pictureUrl, let titleLabel = selectedPicture?.title else { return }
        destinationVC.pictureUrl = pictureUrl
        destinationVC.titleLabelText = titleLabel
    }
    
    func constructPhotoUrlString(with farmId: Int, serverId: String, id: String, secret: String) -> String {
        return "https://farm\(farmId).staticflickr.com/\(serverId)/\(id)_\(secret).jpg"
    }
    
    func fetchFlickrPictures(with completion: @escaping () -> Void) {
        SVProgressHUD.show()
        currentlyRequestingPictures = true
        
        Alamofire.request(FlickrApi.baseUrl , method: .get, parameters: ["method" : FlickrApi.searchPicturesMethod, "api_key" : FlickrApi.apiKey, "format" : "json", "nojsoncallback" : 1, "text" : filterText, "page" : pageNumber])
            .validate()
            .responseJSON { response in
                guard response.result.isSuccess else {
                    //                    print("Error while fetching remote rooms:" \(String(describing: response.result.error))
                    return
                }
                
                guard let unwrappedData = response.data, let json = try? JSON(data: unwrappedData), let pictures = json["photos"]["photo"].array else {
                    print("Malformed data received from fetchAllRooms service")
                    return
                }
                
                var pictureResultsResponse = [FlickrPicture]()
                self.totalPages = json["photos"]["pages"].int ?? 0
                
                if self.storedSearchTerms == nil {
                    UserDefaults.standard.setValue([String](), forKeyPath: "storedSearchTerms")
                }
                
                if self.storedSearchTerms?.contains(self.filterText) == false {
                    self.storedSearchTerms?.append(self.filterText)
                }
                
                for currentPictureIndex in 0..<pictures.count {
                    let farmId = json["photos"]["photo"][currentPictureIndex]["farm"].int ?? 0
                    let serverId = json["photos"]["photo"][currentPictureIndex]["server"].string ?? ""
                    let id = json["photos"]["photo"][currentPictureIndex]["id"].string ?? ""
                    let secret = json["photos"]["photo"][currentPictureIndex]["secret"].string ?? ""
                    let title = json["photos"]["photo"][currentPictureIndex]["title"].string ?? ""
                    let pictureUrl = self.constructPhotoUrlString(with: farmId, serverId: serverId, id: id, secret: secret)
                    let picture = FlickrPicture(pictureUrl: pictureUrl, title: title)
                    pictureResultsResponse.append(picture)
                }
                
                if self.pageNumber == 1 {
                    self.pictureResults = pictureResultsResponse
                } else {
                    self.pictureResults += pictureResultsResponse
                }
                
                self.currentlyRequestingPictures = false
                completion()
        }
    }
}

extension SearchPicturesViewController : UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filterText != "" {
            return pictureResults.count > 0 ? pictureResults.count : 0
        } else {
            return storedSearchTerms?.count ?? 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if filterText != "" {
            let pictureResultCell = tableView.dequeueReusableCell(withIdentifier: "PictureResultTableViewCell", for: indexPath) as! PictureResultTableViewCell
            pictureResultCell.thumbnailImageView.sd_setImage(with: URL(string: pictureResults[indexPath.row].pictureUrl ?? ""), placeholderImage: UIImage())
            pictureResultCell.titleLabel.text = pictureResults[indexPath.row].title ?? ""
            pictureResultCell.selectionStyle = .none
            return pictureResultCell
        } else {
            let storedSearchTermCell = tableView.dequeueReusableCell(withIdentifier: "StoredSearchTermTableViewCell", for: indexPath) as! StoredSearchTermTableViewCell
            storedSearchTermCell.selectionStyle = .none
            storedSearchTermCell.searchTermLabel.text = storedSearchTerms?[indexPath.row] ?? ""
            return storedSearchTermCell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if filterText != "" {
            selectedPicture = pictureResults[indexPath.row]
            performSegue(withIdentifier: "SearchPicturesViewController_to_InspectPictureViewController", sender: self)
        } else {
            filterText = storedSearchTerms?[indexPath.row] ?? ""
            pictureSearchBar.text = filterText
            pictureSearchBar.resignFirstResponder()
            fetchFlickrPictures {
                self.pictureResultsTableView.reloadData()
                SVProgressHUD.dismiss()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if filterText != "" {
            return 70
        } else {
            return 40
        }
    }
}

extension SearchPicturesViewController : UISearchBarDelegate {
    
    func resetResults() {
        pageNumber = 1
        currentlyRequestingPictures = false
        pictureResults.removeAll()
        pictureResultsTableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            filterText = ""
            resetResults()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        userTappedDone = true
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let searchBarText = searchBar.text else { return false }
        searchTextTimer.invalidate()
        
        if (searchBarText.count == 1 && text == "") || (searchBarText.count == 0) {
            filterText = ""
            resetResults()
        } else {
            if text == "\n" {
                return true
            }
            resetResults()
            userTappedDone = false
            filterText = text == "" ? "\(searchBarText.dropLast())" : "\(searchBarText)\(text)"
            currentlyRequestingPictures = true
            searchTextTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(1.0), repeats: false) { (timer) in
                self.fetchFlickrPictures {
                    self.pictureResultsTableView.reloadData()
                    SVProgressHUD.dismiss()
                }
            }
        }
        
        return true
    }
}

extension SearchPicturesViewController : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let reachedEndOfScrollView = scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height
        if reachedEndOfScrollView {
            if !currentlyRequestingPictures && !reachedEndOfPictures && !userTappedDone && filterText != "" {
                self.pageNumber += 1
                currentlyRequestingPictures = true
                self.fetchFlickrPictures {
                    self.pictureResultsTableView.reloadData()
                    SVProgressHUD.dismiss()
                    self.currentlyRequestingPictures = false
                }
            }
        }
    }
}
