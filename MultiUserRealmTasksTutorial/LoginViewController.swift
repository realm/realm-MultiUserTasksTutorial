//
//  ViewController.swift
//  MultiUserRealmTasksTutorial
//
//  Created by David Spector on 6/6/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import UIKit
import RealmSwift
import RealmLoginKit

class TasksLoginViewController: UIViewController {
    var loginViewController: LoginViewController!
    var token: NotificationToken!
    var myIdentity = SyncUser.current?.identity!
    var thePersonRecord: Person?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    
    override func viewDidAppear(_ animated: Bool) {
        loginViewController = LoginViewController(style: .lightOpaque)
        
        loginViewController.isServerURLFieldHidden = true // the user doesn't need to see the server IP in production.
        loginViewController.isRegistering = true
        loginViewController.copyrightLabelText = ""
        
        if (SyncUser.current != nil) {
            // yup - we've got a stored session, so just go right to the UITabView
            Realm.Configuration.defaultConfiguration = Constants.commonRealmConfig
            
            performSegue(withIdentifier: Constants.kLoginToMainView, sender: self)
        } else {
            // show the RealmLoginKit controller
            //loginViewController = LoginViewController(style: .lightOpaque)
            if loginViewController!.serverURL == nil {
                loginViewController!.serverURL = Constants.syncAuthURL.absoluteString
            }
            // Set a closure that will be called on successful login
            loginViewController.loginSuccessfulHandler = { user in
                DispatchQueue.main.async {
                    
                    Realm.asyncOpen(configuration: Constants.commonRealmConfig) { realm, error in
                        if let realm = realm {
                            Realm.Configuration.defaultConfiguration = Constants.commonRealmConfig
                            self.thePersonRecord = Person.createProfile()   // let's make this person a local profile in /~/BingoPrivate
                            // then dismiss the login view, and...
                            self.loginViewController!.dismiss(animated: true, completion: nil)
                            
                            // hop right into the main view for the app (this will be set up by the positioning of the tabs in either app
                            self.performSegue(withIdentifier: Constants.kLoginToMainView, sender: nil)
                            
                        } else if let error = error {
                            print("An error occurred while loggin in: \(error.localizedDescription)")
                        }
                    } // of asyncOpen()
                    
                } // of main queue dispatch
            }// of login controller
            
            present(loginViewController, animated: true, completion: nil)
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

