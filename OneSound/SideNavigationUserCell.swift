//
//  SideNavigationUserCell.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class SideNavigationUserCell: UITableViewCell {

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var blurredUserImage: UIImageView!
    @IBOutlet weak var userLabel: OSLabel!
    
    var pL = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        userImage.layer.cornerRadius = 5
        userImage.layer.borderColor = UIColor.white().CGColor
        userImage.layer.borderWidth = 1.5
        userImage.clipsToBounds = true
        
        
        // Stop cell color from changing when selected
        selectionStyle = UITableViewCellSelectionStyle.None
        
        refresh()
        
        // Make view respond to network reachability changes and user information changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: LocalUserInformationDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: FacebookSessionChangeNotification, object: nil)
    }
    
    func refresh() {
        println("refreshing SideNavigationUserCell")
        
        if LocalUser.sharedUser.setup == true {
            // If user exists
            println("user is setup")
            let userName = LocalUser.sharedUser.name
            userLabel.text = userName
            
            if LocalUser.sharedUser.guest == false && LocalUser.sharedUser.photo != nil {
                // If user isn't a guest and has a valid photo
                println("full user with valid photo; use their photo")
                userImage.image = LocalUser.sharedUser.photo
                
                let blurredImage = LocalUser.sharedUser.photo!.applyBlurWithRadius(2, tintColor: nil, saturationDeltaFactor: 1.3, maskImage: nil)
                blurredUserImage.image = blurredImage
                
                setupOSLabelToDefaultDesiredLook(userLabel)
                userLabel.outlineWidth = 1.5
                userLabel.attributedText =
                    NSAttributedString(
                        string: userName,
                        attributes:
                        [
                            NSFontAttributeName: userLabel.font,
                            NSForegroundColorAttributeName: userLabel.textColor,
                            NSKernAttributeName: userLabel.kerning
                        ])
            } else {
                // If user guest or doesn't have valid photo
                println("guest user or invalid photo, use user color")
                userImage.image = nil
                userImage.backgroundColor = LocalUser.sharedUser.colorToUIColor
                
                blurredUserImage.image = nil
                
                resetOSLabelToBlackUILabel(userLabel)
            }
        }
        else {
            // User isn't setup, check if any info saved in NSUserDefaults
            println("user isn't setup")
            let defaults = NSUserDefaults.standardUserDefaults()
            let userSavedName = defaults.objectForKey(userNameKey) as? String
            let userSavedColor = defaults.objectForKey(userColorKey) as? String
            let userSavedIsGuest = defaults.boolForKey(userGuestKey)
            
            if userSavedName != nil {
                // If user information can be retreived (assumes getting ANY user info means the rest is saved)
                println("found user info in user defaults")
                userLabel.text = userSavedName
                if userSavedIsGuest {
                    println("saved user was guest")
                    userImage.image = nil
                    blurredUserImage.image = nil
                    resetOSLabelToBlackUILabel(userLabel)
                    
                    if userSavedColor != nil {
                        userImage.backgroundColor = LocalUser.colorToUIColor(userSavedColor!)
                    } else {
                        // In case the userSavedColor info can't be retrieved
                        userImage.backgroundColor = UIColor.grayDark()
                    }
                } else {
                    // Deal with non-guests here
                    println("found full user info in user defaults")
                    if let imageData = defaults.objectForKey(userPhotoUIImageKey) as? NSData! {
                        if imageData != nil {
                            println("image data valid, use their image")
                            let image = UIImage(data: imageData)
                            userImage.image = image
                            
                            let blurredImage = image!.applyBlurWithRadius(2, tintColor: nil, saturationDeltaFactor: 1.3, maskImage: nil)
                            blurredUserImage.image = blurredImage
                            
                            setupOSLabelToDefaultDesiredLook(userLabel)
                            userLabel.outlineWidth = 1.5
                            userLabel.attributedText =
                                NSAttributedString(
                                    string: userSavedName!,
                                    attributes:
                                    [
                                        NSFontAttributeName: userLabel.font,
                                        NSForegroundColorAttributeName: userLabel.textColor,
                                        NSKernAttributeName: userLabel.kerning
                                    ])
                        } else {
                            println("image data valid but was nil, try using their color")
                            userImage.image = nil
                            blurredUserImage.image = nil
                            resetOSLabelToBlackUILabel(userLabel)
                            
                            if userSavedColor != nil  {
                                userImage.backgroundColor = LocalUser.colorToUIColor(userSavedColor!)
                            } else {
                                // In case the userSavedColor info can't be retrieved
                                userImage.backgroundColor = UIColor.grayDark()
                            }
                        }
                    } else {
                        // Couldn't get image
                        println("image data invalid, use their color")
                        userImage.image = nil
                        blurredUserImage.image = nil
                        resetOSLabelToBlackUILabel(userLabel)
                        
                        if userSavedColor != nil  {
                            userImage.backgroundColor = LocalUser.colorToUIColor(userSavedColor!)
                        } else {
                            // In case the userSavedColor info can't be retrieved
                            userImage.backgroundColor = UIColor.grayDark()
                        }
                    }
                }
            } else {
                // Can't retrieve any user info
                println("user isn't setup")
                userLabel.text = "Not Signed In"
                userImage.image = nil
                blurredUserImage.image = nil
                resetOSLabelToBlackUILabel(userLabel)
                userImage.backgroundColor = UIColor.grayDark()
            }
        }
    }
}