//
//  AppUser.swift
//  OneSound
//
//  Created by adam on 7/17/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import Foundation

let UserManagerInformationDidChangeNotification = "UserManagerInformationDidChange"

let service = "com.AdamSchoonmaker.OneSound"
let userIDKeychainKey = "userID"
let userAccessTokenKeychainKey = "userAccessToken"
let userGuestBoolKeychainKey = "userGuestBool"
let userGuestBoolKeychainValueIsGuest = "true"
let userGuestBoolKeychainValueIsNotGuest = "false"

let userNameKey = "name"
let userColorKey = "color"
let userGuestKey = "guest"
let userPhotoUIImageKey = "photo"
let userUpvoteCountKey = "upvote"
let userSongCountKey = "song"
let userHotnessPercentKey = "hotness"

class UserManager {

    var pL = true
    
    var accessToken: String!
    
    var setup = false
    
    var id: Int!
    var name: String!
    var color: String!
    var guest: Bool!
    var photoURL: String?
    var songCount: Int!
    var upvoteCount: Int!
    var hotnessPercent: Int!
    var followers: Int!
    var following: Int!
    
    var photo: UIImage?
    
    class var sharedUser: UserManager {
    struct Static {
        static let userManager = UserManager()
        }
        return Static.userManager
    }
    
    // Returns the UIColor of the user's color
    func colorToUIColor() -> UIColor {
        
        if color == nil {
            setRandomColor()
        }
            
        if let userColor = UserColors(rawValue: color) {
            switch userColor {
            case .Green:
                return UIColor.green()
            case .Purple:
                return UIColor.purple()
            case .Turquoise:
                return UIColor.turquoise()
            case .Yellow:
                return UIColor.yellow()
            case .Red:
                return UIColor.red()
            case .Orange:
                return UIColor.orange()
            }
        }
        return UIColor.clearColor()
    }
    
    // Used to turn a OneSound color string into a UIColor
    class func colorToUIColor(color: String) -> UIColor {
        if let userColor = UserColors(rawValue: color) {
            switch userColor {
            case .Green:
                return UIColor.green()
            case .Purple:
                return UIColor.purple()
            case .Turquoise:
                return UIColor.turquoise()
            case .Yellow:
                return UIColor.yellow()
            case .Red:
                return UIColor.red()
            case .Orange:
                return UIColor.orange()
            }
        }
        return UIColor.clearColor()
    }
    
    func randomColor() -> UserColors {
        // Generates a random number 0-(numberOfOneSoundColors - 1)
        let randomInt = Int(arc4random()) % numberOfOneSoundColors
        // println("random int for color:\(randomInt)")
        switch randomInt {
        case 0:
            return UserColors.Green
        case 1:
            return UserColors.Turquoise
        case 2:
            return UserColors.Purple
        case 3:
            return UserColors.Red
        case 4:
            return UserColors.Orange
        case 5:
            return UserColors.Yellow
        default:
            return UserColors.Turquoise
        }
    }
    
    func setRandomColor() {
        color = randomColor().rawValue
    }
    
    func description() -> String {
        var d = "[USER] id:\(id) name:'\(name)' color:\(color) guest:\(guest) f-ers:\(followers) f-ing:\(following) songs:\(songCount) votes:\(upvoteCount) photo:\(photo) accessToken:\(accessToken) setup:\(setup)"
        
        return d
    }
}

extension UserManager {
    // MARK: Login flow and other networking related code
    
    // For use in the login flow of signing a guest user in
    func signIntoGuestAccount(id: Int, userAccessToken: String) {
        // println("Signing in with GUEST information... userID:\(id)   userAccessToken:\(userAccessToken)")
        
        // Make sure there aren't any saved tokens when signing into guest account
        FBSession.activeSession().closeAndClearTokenInformation()
        
        // Set the saved access token in the header
        OSAPI.sharedClient.requestSerializer.setValue(userAccessToken, forHTTPHeaderField: accessTokenHeaderKey)
        
        OSAPI.sharedClient.GETUserLoginGuest(
            success: {[unowned self] data, responseObject in
                let responseJSON = JSON(responseObject)
                // println(responseJSON)
                
                // Get the guest's new access token
                let newGuestAccessToken = responseJSON["access_token"].string
                let guestUserID = responseJSON["uid"].int
                
                self.updateUserInformationAfterSignIn(userID: guestUserID!, accessToken: newGuestAccessToken!,
                    failure: {[unowned self] task, error in
                        // println("ERROR: Couldn't sign into account, creating new one")
                        // println(error.localizedDescription)
                        self.setupGuestAccount()
                    }
                )
            
            }, failure: {[unowned self] task, error in
                // println("ERROR: Guest account no longer exists, creating new one")
                // println(error.localizedDescription)
                
                // Clear the saved access token in the header
                OSAPI.sharedClient.requestSerializer.setValue("", forHTTPHeaderField: accessTokenHeaderKey)
                
                self.deleteAllSavedUserInformation(
                    completion: {[unowned self] in
                        self.setupGuestAccount()
                    }
                )
            }
        )
    }
    
    // For use in the login flow of creating a guest user
    func setupGuestAccount() {
        // println("Setup guest user")
        
        // Make sure there aren't any saved tokens when setting up guest account
        FBSession.activeSession().closeAndClearTokenInformation()
        
        // Get the guest user creation info from the server
        OSAPI.sharedClient.GETGuestUser(
            success: {[unowned self] data, responseObject in
                let responseJSON = JSON(responseObject)
                // println(responseJSON)
                
                // Get the guest response info
                let guestAccessToken = responseJSON["access_token"].string
                let guestUID = responseJSON["uid"].int
                
                // println("Signing in with GUEST information... userID:\(guestUID)   userAccessToken:\(guestAccessToken)")
                
                if guestAccessToken != nil && guestUID != nil {
                    self.updateUserInformationAfterSignIn(userID: guestUID!, accessToken: guestAccessToken!)
                } else {
                    // Those will be nil when the server is down
                    // TODO: add trying to sign in
                    NSNotificationCenter.defaultCenter().postNotificationName(FinishedLoginFlowNotification, object: nil)
                    let alert = UIAlertView(title: "\(appName) Service Down", message: "\(appName) is currently down for maintenance, we will be back up shortly. Please restart the app and try again", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                    AlertManager.sharedManager.showAlert(alert)
                }
            },
            failure: defaultAFHTTPFailureBlockForSigningIn
        )
    }
    
    func signIntoFullAccount(userID: Int, userAccessToken: String, fbAuthToken: String) {
        
        // Set the saved access token in the header
        OSAPI.sharedClient.requestSerializer.setValue(userAccessToken, forHTTPHeaderField: accessTokenHeaderKey)
        
        OSAPI.sharedClient.GETUserLoginProvider(fbAuthToken,
            success: {[unowned self] data, responseObject in
                let responseJSON = JSON(responseObject)
                // println(responseJSON)
                let activeAccount = responseJSON["active"].bool
                if activeAccount == false {
                    // Haven't seen that Facebook account before
                    // println("Account is inactive; create account")
                    
                    let loginStoryboard = UIStoryboard(name: LoginStoryboardName, bundle: nil)
                    let loginViewController = loginStoryboard.instantiateViewControllerWithIdentifier(LoginViewControllerIdentifier) as! LoginViewController
                    let navC = UINavigationController(rootViewController: loginViewController)
                    
                    getFrontNavigationController()!.presentViewController(navC, animated: true,
                        completion: {[unowned self] in
                            loginViewController.userID = userID
                            loginViewController.userAPIToken = userAccessToken
                            loginViewController.userFacebookToken = fbAuthToken
                        }
                    )
                } else {
                    // Facebook account HAS been seen before
                    // println("Account is active; update information and sign in")
                    
                    let userAccessToken = responseJSON["access_token"].string
                    let userID = responseJSON["uid"].int
                    
                    self.updateUserInformationAfterSignIn(userID: userID!, accessToken: userAccessToken!)
                }
            },
            failure: {[unowned self] task, error in
                // println("ERROR: Failed sign on for full account, setup a guest account")
                // println(error.localizedDescription)
                
                // Clear the saved access token in the header
                OSAPI.sharedClient.requestSerializer.setValue("", forHTTPHeaderField: accessTokenHeaderKey)
                
                if let response = task.response as? NSHTTPURLResponse {
                    // println("errorResponseCode:\(response.statusCode)")
                    if response.statusCode == 401 {
                        // Unauthorized token, so just delete everything
                        self.deleteAllSavedUserInformation(
                            completion: {[unowned self] in
                                self.setupGuestAccount()
                            }
                        )
                    } else if response.statusCode == 500 {
                        NSNotificationCenter.defaultCenter().postNotificationName(FinishedLoginFlowNotification, object: nil)
                    } else {
                        self.setupGuestAccount()
                    }
                } else {
                    self.setupGuestAccount()
                }
            }
        )
    }
    
    func setupFullAccount(userName: String, userColor: String, userID: Int, userAccessToken: String, providerToken: String, respondToChangeAttempt: (Bool) -> (), failure: AFHTTPFailureBlock = defaultAFHTTPFailureBlockForSigningIn) {
        
        // Set the saved access token in the header
        OSAPI.sharedClient.requestSerializer.setValue(userAccessToken, forHTTPHeaderField: accessTokenHeaderKey)
        
        OSAPI.sharedClient.POSTUserProvider(userName, userColor: userColor, providerToken: providerToken,
            success: {[unowned self] data, responseObject in
                let responseJSON = JSON(responseObject)
                // println(responseJSON)
                let status = responseJSON["status"].string
                
                if status == "success" {
                    // Update new user information
                    let newUserAccessToken = responseJSON["access_token"].string
                    UserManager.sharedUser.updateUserInformationAfterSignIn(userID: userID, accessToken: newUserAccessToken!, respondToChangeAttempt: respondToChangeAttempt, failure: failure)
                } else {
                    // Server didn't accept request for new account with that name / color
                    respondToChangeAttempt(false)
                }
                
            },
            failure: {[unowned self] task, error in
                // println("ERROR: Guest account no longer exists, creating new one")
                // println(error.localizedDescription)

                // Clear the saved access token in the header
                OSAPI.sharedClient.requestSerializer.setValue("", forHTTPHeaderField: accessTokenHeaderKey)
                
                if let response = task.response as? NSHTTPURLResponse {
                    // println("errorResponseCode:\(response.statusCode)")
                    if response.statusCode == 401 {
                        // Unauthorized token, so just delete everything
                        self.deleteAllSavedUserInformation(
                            completion: {[unowned self] in
                                self.setupGuestAccount()
                            }
                        )
                    } else {
                        self.setupGuestAccount()
                    }
                } else {
                    self.setupGuestAccount()
                }
            }
        )
    }
    
    // Download the user's record for the userID, update the User info from that json,
    // Update the UserDefaults, and update the Keychain info
    // Update the access token in the header
    func updateUserInformationAfterSignIn(userID id: Int, accessToken token: String, respondToChangeAttempt: ((Bool) -> ())? = nil, failure: AFHTTPFailureBlock = defaultAFHTTPFailureBlockForSigningIn) {
        
        // Update the access token in the header
        OSAPI.sharedClient.requestSerializer.setValue(token, forHTTPHeaderField: accessTokenHeaderKey)
        
        // Get the user's info from the server
        OSAPI.sharedClient.GETUser(id,
            success: {[unowned self] data, responseObject in
                let responseJSON = JSON(responseObject)
                // println(responseJSON)
                
                // Update shared User's information, UserDefaults, and Keychain info
                UserManager.sharedUser.updateUserFromJSON(responseJSON, accessToken: token,
                    completion: {[unowned self] in
                        // Join the party that the user is in
                        PartyManager.sharedParty.refresh()
                        
                        // Save the accounts info in the keychain
                        self.updateKeychainInfoForUserManager(id, accessToken: token)
                        // Send out UserManagerInformationDidChangeNotification
                        NSNotificationCenter.defaultCenter().postNotificationName(UserManagerInformationDidChangeNotification, object: nil)
                        // Let the app know it can it can nav away from the splash screen
                        NSNotificationCenter.defaultCenter().postNotificationName(FinishedLoginFlowNotification, object: nil)
                        
                        if respondToChangeAttempt != nil {
                            respondToChangeAttempt!(true)
                        }
                    },
                    forcePhotoUpdate: true
                )
            }, failure: failure
        )
    }
    
    func updateUserInformationOnServer(name: String?, color: String?, respondToChangeAttempt: ((Bool) -> ())? ) {
        OSAPI.sharedClient.PUTUser(id, newName: name, newColor: color, newLatitude: nil, newLongitude: nil,
            success: {[unowned self] data, responseObject in
                let responseJSON = JSON(responseObject)
                // println(responseJSON)
                let status = responseJSON["status"].string
                
                if status == "success" {
                    NSNotificationCenter.defaultCenter().postNotificationName(UserManagerInformationDidChangeNotification, object: nil)
                    self.updateUserInformationFromServer()
                    if respondToChangeAttempt != nil {respondToChangeAttempt!(true)}
                } else {
                    if respondToChangeAttempt != nil {respondToChangeAttempt!(false)}
                }
            }, failure: defaultAFHTTPFailureBlock
        )
    }
    
    func updateUserLocationOnServer(# latitude: Double?, longitude: Double?) {
        OSAPI.sharedClient.PUTUser(id, newName: nil, newColor: nil, newLatitude: latitude, newLongitude: longitude,
            success: {[unowned self] data, responseObject in
                let responseJSON = JSON(responseObject)
                // println(responseJSON)
                let status = responseJSON["status"].string
                
            }, failure: defaultAFHTTPFailureBlock
        )
    }
    
    func updateUserFromJSON(json: JSON, accessToken: String, forcePhotoUpdate: Bool = false, completion: completionClosure? = nil) {
        // println("Updating UserManager from JSON")
        
        setup = true
        
        self.accessToken = accessToken
        
        id = json["uid"].int
        name = json["name"].string
        color = json["color"].string
        guest = json["guest"].bool
        songCount = json["song_count"].int
        upvoteCount = json["vote_count"].int
        hotnessPercent = json["hotness"].int
        followers = json["followers"].int
        following = json["following"].int
        
        let photoStr = "photo"
        // println("guest:\(guest) json[photo]:\(json[photoStr].string != nil) force:\(forcePhotoUpdate) photoUrl:\(photoURL) photoUrlChanged:\(photoURL != json[photoStr].string)")
        if guest == false && json["photo"].string != nil && (forcePhotoUpdate == true || photoURL == nil || photoURL != json["photo"].string) {
            // If not a guest and a non-empty photoURL gets sent that's different from what it was (or forced)
            // println("Setting new photo URL")
            photoURL = json["photo"].string
            updateUserPhoto(photoURL!)
        } else if guest == true {
            // Guests don't have photos
            photo = nil
            NSUserDefaults.standardUserDefaults().removeObjectForKey(userPhotoUIImageKey)
        }
        
        updateUserDefaultsForUserManager()
        
        if completion != nil {
            completion!()
        }
    }
    
    func updateUserPhoto(urlString: String) {
        SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: urlString), options: nil, progress: nil,
            completed: {[unowned self] image, error, cacheType, boolValue, url in
                if error == nil && image != nil {
                    let smallestSide = (image!.size.height > image!.size.width) ? image!.size.width : image!.size.height
                    self.photo = cropBiggestCenteredSquareImageFromImage(image!, sideLength: smallestSide)
                    // println("Saved new photo for user")
                    NSUserDefaults.standardUserDefaults().setObject(UIImagePNGRepresentation(self.photo), forKey: userPhotoUIImageKey)
                    NSNotificationCenter.defaultCenter().postNotificationName(UserManagerInformationDidChangeNotification, object: nil)
                } else {
                    // println("UNABLE to save new photo for user; download failed")
                }
            }
        )
    }
    
    // For updating the local user when NOT in the login flow
    func updateUserInformationFromServer(addToSuccess: completionClosure? = nil) {
        // println("Updating user information from server (NOT login flow)")
        
        OSAPI.sharedClient.GETUser(id,
            success: {[unowned self] data, responseObject in
                let responseJSON = JSON(responseObject)
                // println(responseJSON)
                
                self.updateUserFromJSON(responseJSON, accessToken: self.accessToken)
                // println(self.description())
                if addToSuccess != nil {
                    addToSuccess!()
                }
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    
    func updateUserDefaultsForUserManager() {
        // println("Updating information for UserManager in UserDefaults")
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(name, forKey: userNameKey)
        defaults.setObject(color, forKey: userColorKey)
        defaults.setBool(guest, forKey: userGuestKey)
        defaults.setInteger(upvoteCount, forKey: userUpvoteCountKey)
        defaults.setInteger(songCount, forKey: userSongCountKey)
        defaults.setInteger(hotnessPercent, forKey: userHotnessPercentKey)
    }
    
    func updateKeychainInfoForUserManager(userID: Int, accessToken: String) {
        // Save the account's info in the keychain
        // println("Updating information for UserManager in Keychain")
        // println("Saved userID to keychain:\(userID)")
        // println("Saved accessToken to keychain:\(accessToken)")
        
        SSKeychain.setPassword(String(userID), forService: service, account: userIDKeychainKey)
        SSKeychain.setPassword(accessToken, forService: service, account: userAccessTokenKeychainKey)
        
        var userGuestKeychainValue = guest! ? userGuestBoolKeychainValueIsGuest : userGuestBoolKeychainValueIsNotGuest
        SSKeychain.setPassword(userGuestKeychainValue, forService: service, account: userGuestBoolKeychainKey)
    }
    
    func deleteAllSavedUserInformation(completion: completionClosure? = nil) {
        photoURL = nil
        photo = nil
        
        // Clear the saved access token in the header
        OSAPI.sharedClient.requestSerializer.setValue("", forHTTPHeaderField: accessTokenHeaderKey)
        
        SSKeychain.deletePasswordForService(service, account: userIDKeychainKey)
        SSKeychain.deletePasswordForService(service, account: userAccessTokenKeychainKey)
        SSKeychain.deletePasswordForService(service, account: userGuestBoolKeychainKey)
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey(userNameKey)
        defaults.removeObjectForKey(userColorKey)
        defaults.removeObjectForKey(userGuestKey)
        defaults.removeObjectForKey(userPhotoUIImageKey)
        defaults.removeObjectForKey(userUpvoteCountKey)
        defaults.removeObjectForKey(userSongCountKey)
        defaults.removeObjectForKey(userHotnessPercentKey)
        
        FBSession.activeSession().closeAndClearTokenInformation()
        
        if completion != nil {
            completion!()
        }
    }
}
