//
//  LoginViewController.swift
//  OneSound
//
//  Created by adam on 7/16/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class LoginViewController: UITableViewController {
    
    let validCharacters = "abcdefghijklmnopqrstuvwxyz1234567890"
    
    @IBOutlet var nameCell: UITableViewCell
    @IBOutlet var nameCellTextField: UITextField
    @IBOutlet var nameCellTextFieldCount: UILabel
    @IBOutlet var colorCell: UITableViewCell
    @IBOutlet var authenticationCell: UITableViewCell
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup nav bar
        navigationItem.title = "Create Account"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "done")
        navigationItem.rightBarButtonItem.enabled = false
        
        // Initialize the text field's delegate and character count label
        nameCellTextField.delegate = self
        nameCellTextField.addTarget(self, action: "textFieldDidChange", forControlEvents: UIControlEvents.EditingChanged)
        updateNameCellTextFieldCount()
        
        // Add tap gesture recognizer to dismiss keyboard when background touched
        //let tap = UITapGestureRecognizer(target: self, action: "tap")
        //tableView.addGestureRecognizer(tap)
    }
    
    func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func done() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func textFieldDidChange() {
        updateNameCellTextFieldCount()
    }
    
    func updateNameCellTextFieldCount() {
        // Update label
        nameCellTextFieldCount.text = "\(nameCellTextField.text.utf16count)/15"
        
        // Change color based on number of characters
        switch nameCellTextField.text.utf16count {
        case 1...10:
            nameCellTextFieldCount.textColor = UIColor.green()
        case 11...13:
            nameCellTextFieldCount.textColor = UIColor.orange()
        case 13...15:
            nameCellTextFieldCount.textColor = UIColor.red()
        default:
            nameCellTextFieldCount.textColor = UIColor.black()
        }
    }
    
    func tap() {
        // Dismiss the keyboard whenever the background is touched while editing
        tableView.endEditing(true)
    }
}

extension LoginViewController: UITableViewDataSource {
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        switch indexPath.section {
        case 0:
            return nameCell
        case 1:
            return colorCell
        case 2:
            return authenticationCell
        default:
            println("Error: LoginViewController cellForRowAtIndexPath couldn't get cell")
            return UITableViewCell()
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return 3
    }
}

extension LoginViewController: UITableViewDelegate {
}

extension LoginViewController: UITextFieldDelegate {
    func textField(textField: UITextField!, shouldChangeCharactersInRange range: NSRange, replacementString string: String!) -> Bool {
        // Returns false if any of the replacementString characters are invalid
        for c in String(string) {
            if !validCharacters.hasSubstringCaseInsensitive(String(c)) {
                return false
            }
        }
        
        let newLength = textField.text.utf16count + string.utf16count - range.length
        return ((newLength > 15) ? false : true)
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        nameCellTextField.resignFirstResponder()
        return true
    }
}