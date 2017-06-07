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
        loginViewController.isServerURLFieldHidden = false
        loginViewController.isRegistering = true
        
        if (SyncUser.current != nil) {
            // yup - we've got a stored session, so just go right to the UITabView
            Realm.Configuration.defaultConfiguration = Constants.commonRealmConfig
            
            performSegue(withIdentifier: Constants.kLoginToMainView, sender: self)
        } else {
            // show the RealmLoginKit controller
            if loginViewController!.serverURL == nil {
                loginViewController!.serverURL = Constants.syncAuthURL.absoluteString
            }
            // Set a closure that will be called on successful login
            loginViewController.loginSuccessfulHandler = { user in
                DispatchQueue.main.async {
                    // this AsyncOpen call will open the described Realm and wait for it to download before calling its closure
                    Realm.asyncOpen(configuration: Constants.commonRealmConfig) { realm, error in
                        if let realm = realm {
                            Realm.Configuration.defaultConfiguration = Constants.commonRealmConfig
                            self.loginViewController!.dismiss(animated: true, completion: nil)
                            self.performSegue(withIdentifier: Constants.kLoginToMainView, sender: nil)
                            
                        } else if let error = error {
                            print("An error occurred while logging in: \(error.localizedDescription)")
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

