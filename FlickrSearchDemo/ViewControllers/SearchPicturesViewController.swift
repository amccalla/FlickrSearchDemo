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
    
    //used to keep track of pagination for the scroll view in order to know when to stop making requests
    //for the next page
    //
    var reachedEndOfPictures : Bool {
        if totalPages <= 1 {
            return true
        } else {
            return totalPages <= pageNumber
        }
    }
    
    //
    var storedSearchTerms = [String]()
    var filterText = ""
    var currentlyRequestingPictures = false
    var pageNumber = 1
    var totalPages = 0
    var pictureResults = [FlickrPicture]()
    var selectedPicture : FlickrPicture?
    var searchTextTimer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //load in the previously searched terms from userdefaults (if there)
        //
        if UserDefaults.standard.value(forKey: "storedSearchTerms") != nil {
            storedSearchTerms = UserDefaults.standard.stringArray(forKey: "storedSearchTerms")!
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //pass picture data to the overlay
        //
        guard let destinationVC = segue.destination as? InspectPictureViewController, let pictureUrl = selectedPicture?.pictureUrl, let titleLabel = selectedPicture?.title else { return }
        destinationVC.pictureUrl = pictureUrl
        destinationVC.titleLabelText = titleLabel
    }
    
    func constructPhotoUrlString(with farmId: Int, serverId: String, id: String, secret: String) -> String {
        //necessary for constructing Flickr's proper picture url format
        //
        return "https://farm\(farmId).staticflickr.com/\(serverId)/\(id)_\(secret).jpg"
    }
    
    func fetchFlickrPictures(with completion: @escaping () -> Void) {
        SVProgressHUD.show()
        
        //Check if currentlyRequesting whenever you potentially make a network call based on a scrollview position
        //Otherwise network calls can get spammed (see scrollViewDidScroll) below
        //
        currentlyRequestingPictures = true
        
        //Get pictures from Flickr API
        //
        Alamofire.request(FlickrApi.baseUrl , method: .get, parameters: ["method" : FlickrApi.searchPicturesMethod, "api_key" : FlickrApi.apiKey, "format" : "json", "nojsoncallback" : 1, "text" : filterText, "page" : pageNumber])
            .validate()
            .responseJSON { response in
                
                //run checks for a 200 and good data, otherwise abort & display message to user
                //
                guard response.result.isSuccess else {
                    SVProgressHUD.showError(withStatus: "There was a problem when making your request. Please try again in a bit!")
                    return
                }
                
                guard let unwrappedData = response.data, let json = try? JSON(data: unwrappedData), let pictures = json["photos"]["photo"].array else {
                    SVProgressHUD.showError(withStatus: "There was a problem when making your request. Please try again in a bit!")
                    return
                }
                
                //grab a temp array to hold the currently requested page's pictures to
                //determine whether to replace or append to your existing
                //
                var pictureResultsResponse = [FlickrPicture]()
                self.totalPages = json["photos"]["pages"].int ?? 0
                
                if self.storedSearchTerms.contains(self.filterText) == false {
                    self.storedSearchTerms.append(self.filterText)
                    UserDefaults.standard.setValue(self.storedSearchTerms, forKeyPath: "storedSearchTerms")
                }
                
                //grab each picture object's info for storage & store in temp array
                //
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
                
                //should only replace your array, if you're on page 1 & need a clean refresh
                //
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
            return pictureResults.count > 0 ? pictureResults.count : 1
        } else {
            return storedSearchTerms.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Standard Image w/ Title Cell
        //
        if filterText != "" && pictureResults.count > 0 {
            let pictureResultCell = tableView.dequeueReusableCell(withIdentifier: "PictureResultTableViewCell", for: indexPath) as! PictureResultTableViewCell
            pictureResultCell.thumbnailImageView.sd_setImage(with: URL(string: pictureResults[indexPath.row].pictureUrl ?? ""), placeholderImage: UIImage())
            pictureResultCell.titleLabel.text = pictureResults[indexPath.row].title ?? ""
            pictureResultCell.selectionStyle = .none
            return pictureResultCell
        } else {
            //Stored Search Terms Cell (customized for a case w/ no results)
            //
            let storedSearchTermCell = tableView.dequeueReusableCell(withIdentifier: "StoredSearchTermTableViewCell", for: indexPath) as! StoredSearchTermTableViewCell
            storedSearchTermCell.selectionStyle = .none
            storedSearchTermCell.searchTermLabel.text = (pictureResults.count == 0 && filterText != "") ? "No Results Found" : storedSearchTerms[indexPath.row]
            storedSearchTermCell.chevronLabel.isHidden = (pictureResults.count == 0 && filterText != "")
            return storedSearchTermCell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Two cases for cell selection:
        //-Display Expand Photo Overlay
        //-Run a quick search based on stored search term
        //
        if filterText != "" {
            selectedPicture = pictureResults[indexPath.row]
            performSegue(withIdentifier: "SearchPicturesViewController_to_InspectPictureViewController", sender: self)
        } else {
            filterText = storedSearchTerms[indexPath.row]
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
    
    //used for empty text in search bar to start from scratch
    //
    func resetResults() {
        pageNumber = 1
        currentlyRequestingPictures = false
        pictureResults.removeAll()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            filterText = ""
            resetResults()
            pictureResultsTableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        //Searches are run briefly (1 sec) after typing out a term in the search bar (no button pressing needed)
        //Timer responsible for calling a search is only invalidated if the Done Button on keyboard (\n) since it doesn't change
        //search bar text
        //
        guard let searchBarText = searchBar.text else { return false }
        
        if text == "\n" {
            searchTextTimer.invalidate()
        }
        
        //If last character is deleted, reset
        //
        if (searchBarText.count == 1 && text == "") {
            filterText = ""
            resetResults()
            pictureResultsTableView.reloadData()
        } else {
            if text == "\n" {
                return true
            }
            resetResults()
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
        //Detect when the bottom of the table view is reached & only make a call when necessary for the next page of results
        //Checking for if it's already "currently requesting" & if it's reached the last page, helps make sure minimum calls are made
        //i.e. once a page
        //
        let reachedEndOfScrollView = scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height
        if reachedEndOfScrollView {
            if !currentlyRequestingPictures && !reachedEndOfPictures && filterText != "" {
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
