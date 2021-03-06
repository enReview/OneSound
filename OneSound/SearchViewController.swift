//
//  SearchViewController.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

let SearchViewControllerNibName = "SearchViewController"
let PartySearchResultCellIdentifier = "PartySearchResultCell"

class SearchViewController: OSViewController {
    
    @IBOutlet weak var messageLabel1: UILabel?
    @IBOutlet weak var messageLabel2: UILabel?
    
    @IBOutlet weak var partySearchBar: UISearchBar!
    @IBOutlet weak var searchResultsTable: UITableView!
    @IBOutlet weak var animatedOneSoundOne: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var searchTypeControl: UISegmentedControl!
    @IBOutlet weak var searchResultsTableTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var gettingLocationLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    
    private var createPartyButton: UIBarButtonItem!
    private var searchResultsArray = [Party]()
    private let HeightForRows: CGFloat = 64.0
    private let PartySearchBarPlaceholderText = "Enter a party name"
    private let MaxSearchLength = 25
    //let TypingSearchThreshold = 6
    private var firstTypingSearch = true
    private var partySearchTimer: NSTimer = NSTimer()
    
    private var noSearchResults = false
    
    private let TypingSearchServicePeriod: Double = 0.3 // Period in seconds of how often to update state. Play around with it
    private var searchLength = 0
    
    private var searchByLocation = true // True if Location segment selected
    private var hasRecentLocation = false
    private var updateLocationTimer = NSTimer()
    private let UpdateLocationPeriod = 10.0 // Time in seconds that a location is no longer "recent"
    
    
    func updateLocation() {
        hasRecentLocation = false
        searchResultsArray = []
        searchResultsTable.reloadData()
        searchWithLocation()
    }
    
    func createParty() {
        if UserManager.sharedUser.guest == false {
            let createPartyStoryboard = UIStoryboard(name: CreatePartyStoryboardName, bundle: nil)
            let createPartyViewController = createPartyStoryboard.instantiateViewControllerWithIdentifier(CreatePartyViewControllerIdentifier) as! CreatePartyViewController
            createPartyViewController.partyAlreadyExists = false
            // TODO: create the delegate methods and see what they mean
            //createPartyViewController.delegate = self
            let navC = UINavigationController(rootViewController: createPartyViewController)
            
            getFrontNavigationController()?.presentViewController(navC, animated: true, completion: nil)
        } else {
            let alert = UIAlertView(title: "Guests cannot create parties", message: "To create a party go to the Profile and sign in with Facebook, then try again", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Profile")
            alert.tag = AlertTag.GuestCreatingParty.rawValue
            alert.show()
        }
    }
    
    @IBAction func onRetryLocationSearch(sender: AnyObject) {
        retryButton.hidden = true
        setTableBackgroundViewWithMessages(self.searchResultsTable, "", "")
        searchWithLocation()
    }
    
    @IBAction func changeSearchType(sender: AnyObject) {
        prepareForSelectedSearchType()
        updateUI()
        searchWithLocation()
    }
    
    func prepareForSelectedSearchType() {
        searchByLocation = searchTypeControl.selectedSegmentIndex == 0
        
        if !searchByLocation { hasRecentLocation = false }
        
        searchResultsArray = []
        searchResultsTable.reloadData()
        noSearchResults = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        osvcVariables.screenName = SearchViewControllerNibName
        
        title = "Party Search"
        
        // Setup toolbar
        toolbar.delegate = self
        toolbar.setBackgroundImage(UIImage(named: "toolbarBackground"), forToolbarPosition: UIBarPosition.TopAttached, barMetrics: UIBarMetrics.Default)
        toolbar.setShadowImage(UIImage(named: "navigationBarShadow"), forToolbarPosition: UIBarPosition.TopAttached)
        toolbar.translucent = false
        
        // Setup retry button
        retryButton.layer.borderWidth = 1
        retryButton.layer.borderColor = UIColor.grayDark().CGColor
        retryButton.layer.cornerRadius = 5
        retryButton.layer.masksToBounds = true
        
        // Setup side menu button
        let fnc = getFrontNavigationController()
        let sideMenuButtonItem = UIBarButtonItem(image: UIImage(named: "sideMenuToggleIcon"), style: UIBarButtonItemStyle.Plain, target: fnc, action: "toggleSideMenu")
        navigationItem.leftBarButtonItem = sideMenuButtonItem
        
        // Stop view from being covered by the nav bar / laid out from top of screen
        edgesForExtendedLayout = UIRectEdge.None
        
        createPartyButton = UIBarButtonItem(title: "Create", style: UIBarButtonItemStyle.Plain, target: self, action: "createParty")
        navigationItem.rightBarButtonItem = createPartyButton
        
        // Set the table cells to use
        let nib = UINib(nibName: PartySearchResultCellNibName, bundle: nil)
        searchResultsTable.registerNib(nib, forCellReuseIdentifier: PartySearchResultCellIdentifier)
        // Creating an (empty) footer stops table from showing empty cells
        searchResultsTable.tableFooterView = UIView(frame: CGRectZero)
        
        // Setup the search bar
        partySearchBar.delegate = self
        partySearchBar.enablesReturnKeyAutomatically = true
        partySearchBar.layer.borderWidth = 1
        partySearchBar.layer.borderColor = UIColor.grayLight().CGColor
        
        let tap = UITapGestureRecognizer(target: self, action: "tap")
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // Setup loading animation
        //animatedOneSoundOne.animationImages = [loadingOSLogo2, loadingOSLogo1, loadingOSLogo0, loadingOSLogo1]
        //animatedOneSoundOne.animationDuration = 1.5
        //animatedOneSoundOne.hidden = true
        activityIndicator.hidden = true
        
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and UserManager is setup
        // Also will update the "Create" button
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", name: UserManagerInformationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Makes it look like the toolbar is part of the navigation bar
        navigationController?.navigationBar.translucent = false
        navigationController?.navigationBar.shadowImage = UIImage()
        
        prepareForSelectedSearchType()
        updateUI()
        searchWithLocation()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Restore nav and toolbar appearance
        getFrontNavigationController()?.setupNavigationAndToolbarAppearance()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // Remove the results so they have to search again and keep the info fresh when they come back
        noSearchResults = false
        hasRecentLocation = false
        searchResultsArray = []
        searchResultsTable.reloadData()
        updateLocationTimer.invalidate()
    }
    
    // The text in the field has changed
    func textFieldDidChange() {
        // Make changes based on the number of characters in the text field
        // TODO: Only allow searching with 3+ characters (not a huge deal)
        // if countElements(partySearchTextField.text as String) > 2 {
    }
    
    func tap() {
        // Dismiss the keyboard whenever the background is touched while editing
        view.endEditing(true)
    }
    
    func loadingAnimationShouldBeAnimating(animating: Bool) {
        if animating {
            //animatedOneSoundOne.hidden = false
            //animatedOneSoundOne.startAnimating()
            activityIndicator.hidden = false
            activityIndicator.startAnimating()
        } else {
            //animatedOneSoundOne.hidden = true
            //animatedOneSoundOne.stopAnimating()
            activityIndicator.hidden = true
            activityIndicator.stopAnimating()
        }
    }
    
    override func updateUI() {
        super.updateUI()
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if UserManager.sharedUser.setup == true {
                hideMessages()
                setViewInfoHidden(false)
                
                //
                // Change UI based on search type
                //
                
                var newSearchResultsTableTopConstraint: NSLayoutConstraint
                if searchByLocation {
                    newSearchResultsTableTopConstraint = NSLayoutConstraint(item: searchResultsTable, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: toolbar, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
                } else {
                    newSearchResultsTableTopConstraint = NSLayoutConstraint(item: searchResultsTable, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: partySearchBar, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 8)
                }
                view.removeConstraint(searchResultsTableTopConstraint)
                view.addConstraint(newSearchResultsTableTopConstraint)
                searchResultsTableTopConstraint = newSearchResultsTableTopConstraint
                
                partySearchBar.hidden = searchByLocation
                
                if !searchByLocation {
                    retryButton.hidden = true
                    updateLocationTimer.invalidate()
                    
                    // Stop animation "updating location" when name is pressed
                    activityIndicator.stopAnimating()
                    activityIndicator.hidden = true
                    gettingLocationLabel.hidden = true
                }
                
            } else {
                setViewInfoHidden(true)
                showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart OneSound")
                disableButtons()
                searchResultsArray = []
                searchResultsTable.reloadData()
            }
        } else {
            setViewInfoHidden(true)
            showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use OneSound")
            disableButtons()
            searchResultsArray = []
            searchResultsTable.reloadData()
        }
    }
    
    func setViewInfoHidden(hidden: Bool) {
        partySearchBar.hidden = hidden
        searchResultsTable.hidden = hidden
        
        if (hidden)
        {
            //animatedOneSoundOne.hidden = hidden
            activityIndicator.hidden = hidden
            gettingLocationLabel.hidden = hidden
            retryButton.hidden = hidden
        }
    }
    
    func showMessages(mainLine: String?, detailLine: String?) {
        if mainLine != nil {
            messageLabel1!.alpha = 1
            messageLabel1!.text = mainLine
        }
        if detailLine != nil {
            messageLabel2!.alpha = 1
            messageLabel2!.text = detailLine
        }
    }
    
    func disableButtons() {
        createPartyButton.enabled = false
    }
    
    func hideMessages() {
        messageLabel1!.alpha = 0
        messageLabel1!.text = ""
        messageLabel2!.alpha = 0
        messageLabel2!.text = ""
    }
}

extension SearchViewController {
    // MARK: Searching
    
    func searchWithName(searchTextLength: Int, isSearchButtonPressed: Bool) {
        // Hide the keyboard
        //songSearchBar.resignFirstResponder()
        
        // Empty the table, reload to show its empty, start the animation
        noSearchResults = false // Decides if the table will show party rows, or a "no parties found" message
        searchResultsArray = []
        searchResultsTable.reloadData()
        loadingAnimationShouldBeAnimating(true)
        
        let searchStr = partySearchBar.text
        OSAPI.sharedClient.GETPartySearch(searchStr,
            success: {data, responseObject in
                let responseJSON = JSON(responseObject)
                // println(responseJSON)
                let partiesArray = responseJSON.array
                // println(partiesArray!)
                // println(partiesArray!.count)
                
                // Get the parties in the results and store them
                var newPartySearchResults = [Party]()
                if partiesArray != nil {
                    for result in partiesArray! {
                        //println(result)
                        newPartySearchResults.append(Party(json: result))
                    }
                }
                
                // This bool decides whether the table will show party rows, or a "no parties found" message
                self.noSearchResults = (partiesArray!.count == 0)
                
                // Update the party results, reload the table to show them, stop animating
                self.searchResultsArray = newPartySearchResults
                self.searchResultsTable.reloadData()
                self.loadingAnimationShouldBeAnimating(false)
            },
            failure: { task, error in
                self.loadingAnimationShouldBeAnimating(false)
                defaultAFHTTPFailureBlock!(task: task, error: error)
            }
        )
    }
    
    func searchWithName() {//searchTextLength: Int = 0, isSearchButtonPressed: Bool) {
        // Hide the keyboard
        //songSearchBar.resignFirstResponder()
        if searchLength > 0 {
            if firstTypingSearch {
                // Empty the table, reload to show its empty, start the animation
                firstTypingSearch = false
                noSearchResults = false // Decides if the table will show party rows, or a "no parties found" message
                searchResultsArray = []
                searchResultsTable.reloadData()
                loadingAnimationShouldBeAnimating(true)
            } else {
                loadingAnimationShouldBeAnimating(false)
            }
            
            let searchStr = partySearchBar.text
            OSAPI.sharedClient.GETPartySearch(searchStr,
                success: {data, responseObject in
                    let responseJSON = JSON(responseObject)
                    // println(responseJSON)
                    let partiesArray = responseJSON.array
                    // println(partiesArray!)
                    // println(partiesArray!.count)
                    
                    // Get the parties in the results and store them
                    var newPartySearchResults = [Party]()
                    if partiesArray != nil {
                        for result in partiesArray! {
                            //println(result)
                            newPartySearchResults.append(Party(json: result))
                        }
                    }
                    
                    // This bool decides whether the table will show party rows, or a "no parties found" message
                    self.noSearchResults = (partiesArray!.count == 0)
                    
                    // Update the party results, reload the table to show them, stop animating
                    self.searchResultsArray = newPartySearchResults
                    self.searchResultsTable.reloadData()
                    self.loadingAnimationShouldBeAnimating(false)
                },
                failure: { task, error in
                    self.loadingAnimationShouldBeAnimating(false)
                    defaultAFHTTPFailureBlock!(task: task, error: error)
                }
            )
        }
    }
    
    func searchWithLocation() {
        if hasRecentLocation || !searchByLocation {
            loadingAnimationShouldBeAnimating(false)
            gettingLocationLabel.hidden = true
            return
        }
        
        loadingAnimationShouldBeAnimating(true)
        gettingLocationLabel.hidden = false
        
        LocationManager.sharedManager.getLocationForPartySearch(
            success: { location, accuracy in
                self.hasRecentLocation = true
                let latitude = location.coordinate.latitude
                let longitude = location.coordinate.longitude
                
                // Empty the table, reload to show its empty, start the animation
                self.noSearchResults = false // Decides if the table will show party rows, or a "no parties found" message
                self.searchResultsArray = []
                self.searchResultsTable.reloadData()
                
                OSAPI.sharedClient.GETPartySearchNearby(latitude, longitude: longitude,
                    success: { data, responseObject in
                        if !self.searchByLocation { return }
                        dispatchAsyncToMainQueue(action: {
                            let responseJSON = JSON(responseObject)
                            // println(responseJSON)
                            let partiesArray = responseJSON.array
                            // println(partiesArray!)
                            // println(partiesArray!.count)
                            
                            // Get the parties in the results and store them
                            var newPartySearchResults = [Party]()
                            if partiesArray != nil {
                                for result in partiesArray! {
                                    //println(result)
                                    newPartySearchResults.append(Party(json: result))
                                }
                            }
                            
                            // This bool decides whether the table will show party rows, or a "no parties found" message
                            self.noSearchResults = (partiesArray!.count == 0)
                            
                            // Update the party results, reload the table to show them, stop animating
                            self.searchResultsArray = newPartySearchResults
                            self.searchResultsTable.reloadData()
                            self.loadingAnimationShouldBeAnimating(false)
                            self.gettingLocationLabel.hidden = true
                            
                            // Start a timer to update the Location
                            self.updateLocationTimer.invalidate()
                            self.updateLocationTimer = NSTimer.scheduledTimerWithTimeInterval(self.UpdateLocationPeriod, target: self, selector: "updateLocation", userInfo: nil, repeats: false)
                        })
                    },
                    failure: { task, error in
                        dispatchAsyncToMainQueue(action: {
                            self.loadingAnimationShouldBeAnimating(false)
                            self.gettingLocationLabel.hidden = true
                            defaultAFHTTPFailureBlock!(task: task, error: error)
                        })
                    }
                )
            },
            failure: { errorDescription in
                dispatchAsyncToMainQueue(action: {
                    if self.searchByLocation {
                        self.hasRecentLocation = false
                        self.loadingAnimationShouldBeAnimating(false)
                        self.gettingLocationLabel.hidden = true
                        self.retryButton.hidden = false
                        let error = errorDescription
                        setTableBackgroundViewWithMessages(self.searchResultsTable, "Location Problem", error)
                    }
                })
            }
        )
    }
}

extension SearchViewController: UITableViewDataSource {
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResultsArray.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if !noSearchResults {
            tableView.backgroundView = nil
            return 1
        } else {
            // Display a message when the table is empty after searching
            setTableBackgroundViewWithMessages(tableView, "No parties found", getTableViewBackgroundMessageFromSelectedSegment())
            return 0
        }
    }
    
    func getTableViewBackgroundMessageFromSelectedSegment() -> String {
        if searchTypeControl.selectedSegmentIndex == 0 {
            return "There are no parties in your area, try searching by name instead"
        } else {
            return "Please try searching with a different name"
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = searchResultsTable.dequeueReusableCellWithIdentifier(PartySearchResultCellIdentifier, forIndexPath: indexPath) as! PartySearchResultCell
        
        let result = searchResultsArray[indexPath.row]
        
        var nameText: String = (result.name != nil) ? result.name! : ""
        var userText: String = (result.hostName != nil) ? "Created by \(result.hostName!)" : "Created by Host"
        var membersText: String = (result.memberCount != nil) ? "\(thousandsFormatter.stringFromNumber(NSNumber(integer: result.memberCount!))!) members" : "0 members"
        var locationText: String = (result.distance != nil) ? "\(result.distance!) mi" : ""
        
        cell.nameLabel.text = nameText
        cell.userNameLabel.text = userText
        cell.memberCountLabel.text = membersText
        cell.locationLabel.text = locationText
        
        cell.locationImage.hidden = result.distance == nil
        cell.locationLabel.hidden = result.distance == nil

        return cell
    }
}

extension SearchViewController: UITableViewDelegate {
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let selectedParty = searchResultsArray[indexPath.row]
        
        if UserManager.sharedUser.setup == true {
            PartyManager.sharedParty.joinParty(selectedParty.partyID,
                JSONUpdateCompletion: {
                    PartyManager.sharedParty.refresh(completion: {
                        if PartyManager.sharedParty.state != .None {
                            // Navigate to the party
                            getAppDelegate()!.sideMenuViewController.programaticallySelectRow(1)
                        } else {
                            let alert = UIAlertView(title: "Problem Joining Party", message: "Unable to join party at this time, please try again", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                            AlertManager.sharedManager.showAlert(alert)
                        }
                        
                        self.searchResultsArray = [Party]() // Remove the results so they have to search again
                        tableView.reloadData()
                    })
                    
                    if PartyManager.sharedParty.state != .None {
                        getAppDelegate()!.sideMenuViewController.programaticallySelectRow(1)
                    }
                }, failureAddOn: {
                    PartyManager.sharedParty.refresh()
                    self.searchResultsArray = [] // Remove the results so they have to search again
                    tableView.reloadData()
                    let alert = UIAlertView(title: "Problem Joining Party", message: "Unable to join party at this time, please try again", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                    AlertManager.sharedManager.showAlert(alert)
                }
            )
        } else {
            let alert = UIAlertView(title: "Not Signed In", message: "Please sign into an account before joining a party", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
            AlertManager.sharedManager.showAlert(alert)
        }
        
        // Deselect it after
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return HeightForRows
    }
}

extension SearchViewController: UIScrollViewDelegate {
    // MARK: UIScrollViewDelegate
    
    // Dismisses the keyboard when the user was editing text after searching, then looks at results again
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        partySearchBar.resignFirstResponder()
    }
}

extension SearchViewController: UISearchBarDelegate {
    // MARK: UISearchBarDelegate
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        /*if countElements(searchText) >= TypingSearchThreshold {
            search(searchTextLength:countElements(searchText), isSearchButtonPressed:false)
        }*/
        
        // Clear search data (this should happen when user presses the 'x' on the right side)
        searchLength = count(searchText)
        if count(searchText) == 0 {
            noSearchResults = false
            searchResultsArray = []
            searchResultsTable.reloadData()
            firstTypingSearch = true
            partySearchTimer.invalidate()
        } else {
            partySearchTimer.invalidate()
            partySearchTimer = NSTimer.scheduledTimerWithTimeInterval(TypingSearchServicePeriod, target: self, selector: "searchWithName", userInfo: nil, repeats: false)
        }
        
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.placeholder = nil
        firstTypingSearch = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.placeholder = PartySearchBarPlaceholderText
    }
    
    // Hide keyboard when user presses "Search", initiate the search
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        removeLeadingWhitespaceFromSearchBar(&partySearchBar!)
        partySearchBar.resignFirstResponder()
        searchWithName(0, isSearchButtonPressed:true)
    }
    
    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        // Returns false if any of the replacementString characters are invalid
        for c in text {
            if c != " " && c != "\n" && !validCharacters.hasSubstringCaseInsensitive(String(c)) {
                return false
            }
        }
        
        if addingOnlyWhitespaceToTextFieldWithOnlyWhitespaceOrEmpty(searchBar.text, text) {
            return false
        }
        
        // Only allow change if 25 or less characters
        let newLength = count(searchBar.text as String) - range.length
        return newLength <= MaxSearchLength
    }
}

extension SearchViewController: SideMenuNavigableViewControllerWithKeyboard {
    // MARK: SideMenuNavigableViewControllerWithKeyboard
    
    func hideKeyboard() {
        partySearchBar.resignFirstResponder()
    }
}

extension SearchViewController: UIAlertViewDelegate {
    // MARK: UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == AlertTag.GuestCreatingParty.rawValue {
            // If guest wants to sign in with Facebook, take them to the profile
            if buttonIndex == 1 {
                getAppDelegate()?.sideMenuViewController.programaticallySelectRow(SideMenuRow.Profile.rawValue)
            }
        }
    }
}

extension SearchViewController: UIToolbarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
}