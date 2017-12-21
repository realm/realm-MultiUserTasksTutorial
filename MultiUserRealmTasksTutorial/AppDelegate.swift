//
//  AppDelegate.swift
//  MultiUserRealmTasksTutorial
//
//  Created by Ian Ward on 12/19/17.
//  Copyright © 2017 Ian Ward. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:[UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: TasksLoginViewController(style: .plain))
        window?.makeKeyAndVisible()
        return true
    }
}
