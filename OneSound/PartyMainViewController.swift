//
//  PartyMainViewController.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit
import AVFoundation

let PartyMainViewControllerNibName = "PartyMainViewController"
let PlayPauseButtonAnimationTime = 0.2

let defaultUserImageForMainParty = UIImage(named: "defaultUserImageForMainParty")

let songImageForNoSongToPlay = UIImage(named: "noSongToPlay")
let songImageForNoSongArtwork = UIImage(named: "songImageForNoSongArtwork")

let thumbsUpSelectedMainParty = UIImage(named: "thumbsUpSelectedMainParty")
let thumbsUpUnselectedMainParty = UIImage(named: "thumbsUpUnselectedMainParty")
let thumbsDownSelectedMainParty = UIImage(named: "thumbsDownSelectedMainParty")
let thumbsDownUnselectedMainParty = UIImage(named: "thumbsDownUnselectedMainParty")

class PartyMainViewController: UIViewController {
    
    let userMainPartyImageCache = (UIApplication.sharedApplication().delegate as AppDelegate).userMainPartyImageCache
    
    @IBOutlet weak var messageLabel1: UILabel?
    @IBOutlet weak var messageLabel2: UILabel?
    
    @IBOutlet weak var songImage: UIImageView?
    @IBOutlet weak var soundcloudLogo: UIImageView?
    @IBOutlet weak var playButton: UIButton?
    @IBOutlet weak var pauseButton: UIButton?
    @IBOutlet weak var songProgress: UIProgressView?
    @IBOutlet weak var songNameLabel: OSLabel!
    @IBOutlet weak var songArtistLabel: OSLabel!
    @IBOutlet weak var songTimeLabel: OSLabel!
    @IBOutlet weak var songImageForLoadingSong: UIImageView!
    @IBOutlet weak var addSongButton: UIButton!
    
    @IBOutlet weak var userView: UIView!
    @IBOutlet weak var shortUserLabel: UILabel!
    @IBOutlet weak var shortThumbsDownButton: UIButton!
    @IBOutlet weak var shortThumbsUpButton: UIButton!
    @IBOutlet weak var tallUserLabel: UILabel!
    @IBOutlet weak var tallThumbsDownButton: UIButton!
    @IBOutlet weak var tallThumbsUpButton: UIButton!
    @IBOutlet weak var tallUserImage: UIImageView!
    
    @IBOutlet weak var userUpvoteLabel: UILabel!
    @IBOutlet weak var userSongLabel: UILabel!
    @IBOutlet weak var userHotnessLabel: UILabel!
    @IBOutlet weak var userUpvoteIcon: UIImageView!
    @IBOutlet weak var userSongIcon: UIImageView!
    @IBOutlet weak var userHotnessIcon: UIImageView!
    
    var createPartyButton: UIBarButtonItem!
    var leavePartyButton: UIBarButtonItem!
    var partySettingsButton: UIBarButtonItem!
    var rightBarButton: UIBarButtonItem?
    
    var partyRefreshTimer: NSTimer?
    
    @IBAction func tallThumbsDownPressed(sender: AnyObject) {
        handleThumbsDownPress(sender)
    }
    
    @IBAction func tallThumbsUpPressed(sender: AnyObject) {
        handleThumbsUpPress(sender)
    }
  
    @IBAction func shortThumbsDownPressed(sender: AnyObject) {
        handleThumbsDownPress(sender)
    }
    
    @IBAction func shortThumbsUpPressed(sender: AnyObject) {
        handleThumbsUpPress(sender)
    }
    
    @IBAction func play(sender: AnyObject) {
        LocalParty.sharedParty.playSong()
    }
    
    @IBAction func pause(sender: AnyObject) {
        LocalParty.sharedParty.pauseSong()
    }
    
    @IBAction func addSong(sender: AnyObject) {
        let addSongViewController = AddSongViewController(nibName: AddSongViewControllerNibName, bundle: nil)
        let navC = UINavigationController(rootViewController: addSongViewController)
        presentViewController(navC, animated: true, completion: nil)
    }
    
    func createParty() {
    
    }
    
    func leaveParty() {
    
    }
    
    func changePartySettings() {
    
    }
    
    
    override func viewDidLoad() {
        // This is the delegate to the LocalParty
        LocalParty.sharedParty.delegate = self
        
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and LocalUser is setup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: LocalUserInformationDidChangeNotification, object: nil)
        // Should update when a party song is added
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshAfterAddingSong", name: PartySongWasAddedNotification, object: nil)
        
        songProgress!.progress = 0.0
        
        // Setup the labels
        setupOSLabelToDefaultDesiredLook(songNameLabel!)
        setupOSLabelToDefaultDesiredLook(songArtistLabel!)
        setupOSLabelToDefaultDesiredLook(songTimeLabel!)
        
        // Setup loading animation
        songImageForLoadingSong.animationImages = [loadingSong2, loadingSong1, loadingSong0, loadingSong1]
        songImageForLoadingSong.animationDuration = 1.5
        songImageForLoadingSong.hidden = true
        
        // Setup the thumb up/down buttons
        shortThumbsUpButton.setImage(thumbsUpUnselectedMainParty, forState: UIControlState.Disabled)
        shortThumbsDownButton.setImage(thumbsDownUnselectedMainParty, forState: UIControlState.Disabled)
        
        // Setup the add song button
        addSongButton.backgroundColor = UIColor.blue()
        addSongButton.layer.cornerRadius = 3.0
        
        tallUserImage.layer.cornerRadius = 5.0
        tallUserImage.image = defaultUserImageForMainParty
        
        createPartyButton = UIBarButtonItem(title: "Create", style: UIBarButtonItemStyle.Plain, target: self, action: "createParty")
        leavePartyButton = UIBarButtonItem(title: "Leave", style: UIBarButtonItemStyle.Plain, target: self, action: "leaveParty")
        partySettingsButton = UIBarButtonItem(title: "Settings", style: UIBarButtonItemStyle.Plain, target: self, action: "changePartySettings")
        rightBarButton = createPartyButton

        hideMessages()
        setPartyInfoHidden(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let party = LocalParty.sharedParty
        if party.setup == true && party.name != nil {
            navigationController!.visibleViewController.title = LocalParty.sharedParty.name
            
            if !party.userIsHost {
                partyRefreshTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "refresh", userInfo: nil, repeats: true)
            }
        }
        else {
            navigationController!.visibleViewController.title = "Party"
        }
        
        setRightBarButtonWhenSelected()
        refresh()
    }
    
    override func viewWillDisappear(animated: Bool) {
        if partyRefreshTimer != nil { partyRefreshTimer!.invalidate() }
    }
    
    func setPartyMainVCRightBarButton(# create: Bool, leave: Bool, settings: Bool) {
        if create { rightBarButton = createPartyButton }
        else if leave { rightBarButton = leavePartyButton }
        else if settings { rightBarButton = partySettingsButton }
        else { rightBarButton = nil }
        setRightBarButtonWhenSelected()
    }
    
    // When this is the selected tab of the tab bar controller, set the right nav button to rightBarButton
    func setRightBarButtonWhenSelected() {
        if let ptbc = getPartyTabBarController() {
            ptbc.updateRightBarButtonForMainParty()
        }
    }
    
    func handleThumbsUpPress(button: AnyObject) {
        if let thumbsUpButton = button as? UIButton {
            if thumbsUpButton.selected {
                // If the button is selected before it is pressed, make it unselected
                setThumbsUpUnselected()
                
                // Clear song vote
                if let currentSong = LocalParty.sharedParty.currentSong {
                    LocalParty.sharedParty.songClearVote(currentSong.songID)
                }
                changeUserUpvoteLabelCountBy(-1)
            } else {
                // If the button is unselected before it is pressed
                setThumbsUpSelected()
                
                // Upvote song
                if let currentSong = LocalParty.sharedParty.currentSong {
                    LocalParty.sharedParty.songUpvote(currentSong.songID)
                }
                changeUserUpvoteLabelCountBy(1)
                
                if shortThumbsDownButton.selected || tallThumbsDownButton.selected {
                    setThumbsDownUnselected()
                    changeUserUpvoteLabelCountBy(1)
                }
            }
        }
    }
    
    func handleThumbsDownPress(button: AnyObject) {
        if let thumbsDownButton = button as? UIButton {
            if thumbsDownButton.selected {
                // If the button is selected before it is pressed, make it unselected
                setThumbsDownUnselected()
                
                // Clear song vote
                if let currentSong = LocalParty.sharedParty.currentSong {
                    LocalParty.sharedParty.songClearVote(currentSong.songID)
                }
                changeUserUpvoteLabelCountBy(1)
            } else {
                // If the button is unselected before it is pressed
                setThumbsDownSelected()
                
                // Downvote song
                if let currentSong = LocalParty.sharedParty.currentSong {
                    LocalParty.sharedParty.songDownvote(currentSong.songID)
                }
                changeUserUpvoteLabelCountBy(-1)
                
                if shortThumbsUpButton.selected || tallThumbsUpButton.selected {
                    setThumbsUpUnselected()
                    changeUserUpvoteLabelCountBy(-1)
                }
            }
        }
    }
    
    func resetThumbsUpDownButtons() {
        setThumbsUpUnselected()
        setThumbsDownUnselected()
    }
    
    func changeUserUpvoteLabelCountBy(changeBy: Int) {
        if userUpvoteLabel != nil {
            if let voteCount = userUpvoteLabel!.text!.toInt() {
                let newVoteCount = voteCount + changeBy
                userUpvoteLabel.text = String(newVoteCount)
            }
        }
    }
    
    func setThumbsUpSelected() {
        if shorterIphoneScreen {
            shortThumbsUpButton.setImage(thumbsUpSelectedMainParty, forState: UIControlState.Normal)
            shortThumbsUpButton.selected = true
        } else {
            tallThumbsUpButton.setImage(thumbsUpSelectedMainParty, forState: UIControlState.Normal)
            tallThumbsUpButton.selected = true
        }
    }
    
    func setThumbsUpUnselected() {
        if shorterIphoneScreen {
            shortThumbsUpButton.setImage(thumbsUpUnselectedMainParty, forState: UIControlState.Normal)
            shortThumbsUpButton.selected = false
        } else {
            tallThumbsUpButton.setImage(thumbsUpUnselectedMainParty, forState: UIControlState.Normal)
            tallThumbsUpButton.selected = false
        }
    }
    
    func setThumbsDownSelected() {
        if shorterIphoneScreen {
            shortThumbsDownButton.setImage(thumbsDownSelectedMainParty, forState: UIControlState.Normal)
            shortThumbsDownButton.selected = true
        } else {
            tallThumbsDownButton.setImage(thumbsDownSelectedMainParty, forState: UIControlState.Normal)
            tallThumbsDownButton.selected = true
        }
    }
    
    func setThumbsDownUnselected() {
        if shorterIphoneScreen {
            shortThumbsDownButton.setImage(thumbsDownUnselectedMainParty, forState: UIControlState.Normal)
            shortThumbsDownButton.selected = false
        } else {
            tallThumbsDownButton.setImage(thumbsDownUnselectedMainParty, forState: UIControlState.Normal)
            tallThumbsDownButton.selected = false
        }
    }
    
    func updateSongProgress(progress: Float) {
        songProgress!.progress = progress
        songProgress!.hidden = false
    }
    
    func onPartyRefreshTimer() {
        if !LocalParty.sharedParty.userIsHost { refresh() }
    }
    
    func refreshAfterAddingSong() {
        addSongButton.hidden = true
        refresh()
    }
    
    func refresh() {
        println("refreshing PartyMainViewController")
        LocalParty.sharedParty.refresh()
    }
    
    func clearAllSongInfo() {
        setPartySongImage(songToPlay: false, artworkToShow: false, loadingSong: false, image: nil)
        setPartySongInfo(name: "", artist: "", time: "")
        setPartySongUserInfo(nil, thumbsUp: false, thumbsDown: false)
        resetThumbsUpDownButtons()
    }
    
    func setPartySongUserInfo(user: User?, thumbsUp: Bool, thumbsDown: Bool) {
        showPartySongUserInfo()
        
        if shorterIphoneScreen {
            if user != nil {
                shortUserLabel.text = user!.name
            } else {
                shortUserLabel.text = ""
                shortUserLabel.hidden = true
                shortThumbsUpButton.hidden = true
                shortThumbsDownButton.hidden = true
            }
        } else {
            if user != nil {
                setUserInfoLabelsText(upvoteLabel: userUpvoteLabel, numUpvotes: user!.upvoteCount, songLabel: userSongLabel, numSongs: user!.songCount, hotnessLabel: userHotnessLabel, percentHotness: user!.hotnessPercent, userNameLabel: tallUserLabel, userName: user!.name)
                
                tallUserImage.image = defaultUserImageForMainParty
                if user!.photoURL != nil {
                    setUserMainPartyImageUsingCache(user!.photoURL!)
                }
            } else {
                tallUserLabel.text = ""
                tallThumbsUpButton.hidden = true
                tallThumbsDownButton.hidden = true
                tallUserImage.hidden = true
                
                userUpvoteLabel.text = ""
                userSongLabel.text = ""
                userHotnessLabel.text = ""
                userUpvoteLabel.hidden = true
                userSongLabel.hidden = true
                userHotnessLabel.hidden = true
                userUpvoteIcon.hidden = true
                userSongIcon.hidden = true
                userHotnessIcon.hidden = true
            }
        }
    }
    
    func showPartySongUserInfo() {
        userView!.hidden = false
        
        if shorterIphoneScreen {
            shortUserLabel.hidden = false
            shortThumbsDownButton.hidden = false
            shortThumbsUpButton.hidden = false
        } else {
            tallUserLabel.hidden = false
            tallThumbsDownButton.hidden = false
            tallThumbsUpButton.hidden = false
            tallUserImage.hidden = false
            
            userUpvoteLabel.hidden = false
            userSongLabel.hidden = false
            userHotnessLabel.hidden = false
            userUpvoteIcon.hidden = false
            userSongIcon.hidden = false
            userHotnessIcon.hidden = false
        }
    }
    
    func showPartySongInfo() {
        songNameLabel!.hidden = false
        songArtistLabel!.hidden = false
        songTimeLabel!.hidden = false
        songProgress!.hidden = false
    }
    
    func setPartySongInfo(# name: String, artist: String, time: String) {
        showPartySongInfo()
        
        songNameLabel.attributedText =
            NSAttributedString(
                string: name,
                attributes:
                [
                    NSFontAttributeName: songNameLabel.font,
                    NSForegroundColorAttributeName: songNameLabel.textColor,
                    NSKernAttributeName: songNameLabel.kerning
                ])
        songArtistLabel.attributedText =
            NSAttributedString(
                string: artist,
                attributes:
                [
                    NSFontAttributeName: songArtistLabel.font,
                    NSForegroundColorAttributeName: songArtistLabel.textColor,
                    NSKernAttributeName: songArtistLabel.kerning
                ])
        songTimeLabel.attributedText =
            NSAttributedString(
                string: time,
                attributes:
                [
                    NSFontAttributeName: songTimeLabel.font,
                    NSForegroundColorAttributeName: songTimeLabel.textColor,
                    NSKernAttributeName: songTimeLabel.kerning
                ])
        
        self.songNameLabel!.adjustFontSizeToFit(minFontSize: 14, heightToAdjustFor: 25)
    }
    
    func setPartySongImage(# songToPlay: Bool, artworkToShow: Bool, loadingSong: Bool, image: UIImage?) {
        addSongButton.hidden = true
        
        if loadingSong {
            songImage!.hidden = true
            
            songImageForLoadingSong.hidden = false
            songImageForLoadingSong.startAnimating()
            soundcloudLogo!.hidden = false
            return
        } else {
            songImage!.hidden = false
            
            songImageForLoadingSong.hidden = true
            songImageForLoadingSong.stopAnimating()
        }
        
        if !songToPlay {
            songImage!.image = songImageForNoSongToPlay
            addSongButton.hidden = false
            soundcloudLogo!.hidden = true
            return
        }
        
        soundcloudLogo!.hidden = false
        
        if !artworkToShow {
            songImage!.image = songImageForNoSongArtwork
            soundcloudLogo!.hidden = false
            return
        }
        
        if image != nil {
            songImage!.image = image
            //songImage = UIImageView(image: image)
        } else {
            songImage!.image = songImageForNoSongArtwork
        }
    }
    
    func setPartyInfoHidden(hidden: Bool) {
        if songImage != nil {
            songImage!.hidden = hidden
        }
        
        songNameLabel!.hidden = hidden
        songArtistLabel!.hidden = hidden
        songTimeLabel!.hidden = hidden
        
        // Only set button visibility for hiding; to show them the player must be checked
        // Only set the songImageOverlay to hidden, don't set it to visible with everything else
        // When hiding the party info, reset the song labels to empty and the song progress to 0
        if hidden == true {
            songImageForLoadingSong.hidden = hidden
            
            soundcloudLogo!.hidden = hidden
            
            playButton!.hidden = hidden
            playButton!.alpha = 0.0
            pauseButton!.hidden = hidden
            pauseButton!.alpha = 0.0
            songProgress!.hidden = hidden
            songProgress!.alpha = 0.0
            songProgress!.progress = 0.0
            addSongButton.hidden = hidden
            
            songNameLabel!.text = ""
            songArtistLabel!.text = ""
            songTimeLabel!.text = ""
            
            userView!.hidden = hidden
            if shorterIphoneScreen {
                shortUserLabel!.hidden = hidden
                shortUserLabel!.text = ""
                shortThumbsDownButton!.hidden = hidden
                shortThumbsUpButton!.hidden = hidden
            } else {
                tallUserLabel!.hidden = hidden
                tallUserLabel!.text = ""
                tallThumbsDownButton!.hidden = hidden
                tallThumbsUpButton!.hidden = hidden
                tallUserImage.hidden = hidden
            }
        }
    }
    
    /*
    func updateControls() {
        if let player = LocalParty.sharedParty.audioPlayer {
            
            if player.state == STKAudioPlayerStatePlaying {
                
            }
            
        }
    }*/
    
    func setAudioPlayerButtonsForPlaying(audioPlayerIsPlaying: Bool) {
        // The song progress should always be visible when there's an audio player
        songProgress!.hidden = false
        songProgress!.alpha = 1.0
        
        if audioPlayerIsPlaying {
            // Make pause button active
            if playButton!.hidden == false {
                // Play button is visible; hide it and then show the pause button, then fade it out again
                UIView.animateWithDuration(PlayPauseButtonAnimationTime,
                    animations: {
                        self.playButton!.alpha = 0.0
                    },
                    completion: { boolVal in
                        self.playButton!.hidden = true
                        self.pauseButton!.hidden = false
                        self.pauseButton!.alpha = 1.0
                    }
                )
            } else {
                // Play button is not visible, so just make the pause button active
                pauseButton!.hidden = false
                pauseButton!.alpha = 1.0
            }
        } else {
            // Make play button visible and the pause button inactive
            pauseButton!.hidden = true
            pauseButton!.alpha = 0.0
            playButton!.hidden = false
            UIView.animateWithDuration(PlayPauseButtonAnimationTime,
                animations: {
                    self.playButton!.alpha = 1.0
                }
            )
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
    
    func hideMessages() {
        messageLabel1!.alpha = 0
        messageLabel1!.text = ""
        messageLabel2!.alpha = 0
        messageLabel2!.text = ""
    }
    
    // Sets the user image from the cache if it's there, else downloads and caches it before setting
    func setUserMainPartyImageUsingCache(urlString: String) {
        userMainPartyImageCache.queryDiskCacheForKey(urlString,
            done: { image, imageCacheType in
                if image != nil {
                    self.tallUserImage.image = image
                    self.tallUserImage.setNeedsLayout()
                } else {
                    self.startImageDownload(urlString)
                }
            }
        )
    }
    
    // Sets user image after downloading and caching the image at the urlString into the userMainPartyImageCache
    func startImageDownload(urlString: String) {
        SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: urlString), options: nil, progress: nil,
            completed: { image, error, cacheType, boolValue, url in
                
                if error == nil && image != nil {
                    let processedImage = cropBiggestCenteredSquareImageFromImage(image, sideLength: self.tallUserImage.frame.height)
                    
                    self.userMainPartyImageCache.storeImage(processedImage, forKey: urlString)
                    
                    dispatchAsyncToMainQueue(action: {
                        self.tallUserImage.image = processedImage
                        self.tallUserImage.setNeedsLayout()
                    })
                } else {
                    dispatchAsyncToMainQueue(action: {
                        self.tallUserImage.image = defaultUserImageForMainParty
                        self.tallUserImage.setNeedsLayout()
                    })
                }
            }
        )
    }
    
    
}

extension PartyMainViewController: LocalPartyDelegate {
    
}

/*
extension PartyMainViewController {
    // MARK: handing play/pause from home screen, firstResponder info
    
    override func canBecomeFirstResponder() -> Bool { return true }
    
    override func canResignFirstResponder() -> Bool { return true }
    
    func assignFirstResponder() {
        becomeFirstResponder()
    }
    
    func unassignFirstResponder() {
        resignFirstResponder()
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent) {
        let rc = event.subtype
        println("received remote control \(rc.rawValue)")
        let party = LocalParty.sharedParty
        
        switch rc {
        case .RemoteControlTogglePlayPause:
            if party.audioPlayer.state == STKAudioPlayerStatePlaying {
                party.pauseSong()
            } else {
                party.playSong()
            }
        case .RemoteControlPlay:
            party.playSong()
        case .RemoteControlPause:
            party.pauseSong()
        default:
            break
        }
        
    }
}
*/