//
//  TroubleshootingViewController.swift
//  OneSound
//
//  Created by adam on 1/31/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

let TroubleshootingViewControllerNibName = "TroubleshootingViewController"

class TroubleshootingViewController: UIViewController {

    @IBOutlet weak var textVew: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        textVew.text = troubleshootingStr
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
