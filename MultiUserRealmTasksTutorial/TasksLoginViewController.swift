//
//  TasksLoginViewController.swift
//  MultiUserRealmTasksTutorial
//
//  Created by Ian Ward on 12/19/17.
//  Copyright © 2017 Ian Ward. All rights reserved.
//
import UIKit
import RealmSwift
import RealmLoginKit

class TasksLoginViewController: UITableViewController {
    var loginViewController: LoginViewController!
    var token: NotificationToken!
    var myIdentity = SyncUser.current?.identity!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        loginViewController = LoginViewController(style: .lightOpaque)
        loginViewController.isServerURLFieldHidden = false
        loginViewController.isRegistering = true
        
        if (SyncUser.current != nil) {
            // yup - we've got a stored session, so just go right to the UITabView
            Realm.Configuration.defaultConfiguration = tasksRealmConfig(user: SyncUser.current!)
            
            self.navigationController?.setViewControllers([TasksTableViewController()], animated: true)
            self.loginViewController!.dismiss(animated: true, completion: nil)
        } else {
            // show the RealmLoginKit controller
            if loginViewController!.serverURL == nil {
                loginViewController!.serverURL = Constants.syncAuthURL.absoluteString
            }
            // Set a closure that will be called on successful login
            loginViewController.loginSuccessfulHandler = { user in
                DispatchQueue.main.async {
                    // this AsyncOpen call will open the described Realm and wait for it to download before calling its closure
                    Realm.asyncOpen(configuration: tasksRealmConfig(user: SyncUser.current!)) { realm, error in
                        if realm != nil {
                            Realm.Configuration.defaultConfiguration = tasksRealmConfig(user: SyncUser.current!)

                            //self.loginViewController!.dismiss(animated: true, completion: nil)
                            
                            // let's instantiate the nexty view controller...
                            let tasklistVC = TasksTableViewController()
                            tasklistVC.realm = realm //  and set up its realm reference (since have it).
                            
                            // then we can set the nav controller to use this view and then dismiss the login view
                            self.navigationController?.setViewControllers([tasklistVC], animated: true)
                            self.loginViewController!.dismiss(animated: true, completion: nil)
                            
                        } else if let error = error {
                            print("An error occurred while logging in: \(error.localizedDescription)")
                        }
                    } // of asyncOpen()
                    
                } // of main queue dispatch
            }// of login controller
            
            present(loginViewController, animated: true, completion: nil)
        }
}

}
