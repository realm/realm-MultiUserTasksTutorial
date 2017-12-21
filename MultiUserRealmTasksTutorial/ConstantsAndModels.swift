//
//  ConstantsAndModels.swift
//  MultiUserRealmTasksTutorial
//
//  Created by Ian Ward on 12/20/17.
//  Copyright © 2017 Ian Ward. All rights reserved.
//

import Foundation
import RealmSwift



struct Constants {
    // segue names
    static let      kLoginToMainView                = "loginToTasksViewSegue"
    static let      kExitToLoginViewSegue           = "tasksToLoginViewSegue"
    
    
    // the host that will do the synch - if oure using the Mac dev kit you probably want this to be localhost/127.0.0.1
    // if you are using the Professional or Enterprise Editions, then this will be a host on the Internet
    static let defaultSyncHost                      = "127.0.0.1"
    
    // this is purely for talking to the RMP auth system
    static let syncAuthURL                          = URL(string: "http://\(defaultSyncHost):9080")!
    
    // The following URLs and URI fragments are about talking to the synchronization service and the Realms
    // it manages on behalf of your application:
    static let syncServerURL                        = URL(string: "realm://\(defaultSyncHost):9080/")
    
    // Note: When we say Realm file we mean literally the entire collection of models/schemas inside that Realm...
    // So we need to be very clear what models that are represented by a given Realm.  For example:
    
    // this is a realm where we can store profile info - not covered in the main line of this tutorial
    static let commonRealmURL                       = URL(string: "realm://\(defaultSyncHost):9080/CommonRealm")!
    
    // Note: If Swift supported C-style macros, we could simply define the configuration for the tasks Realm like this:
    //
    static let commonRealmConfig                    = Realm.Configuration(syncConfiguration: SyncConfiguration(user: SyncUser.current!, realmURL: commonRealmURL),objectTypes: [Person.self])
    // However the key bit of information the Realm config needs is which user (e.g., SyncUser) it's being configured with.  As a static
    // this would get set only once at app launch time -- so if your initial user logs out and someone else tries to log in, the
    // configuration would still be using the SyncUser.currrent value obtained at launch. So, instead we'll use the function below which
    // obtains the SyncUser dyanamically.  This same logic appplies to other Realm configs like tasksRealmConfig too.
    
    //  this is a task Realm comptible with the fully version of RealmTasks for iOS/Android/C#
    static let tasksRealmURL                       = URL(string: "realm://\(defaultSyncHost):9080/~/realmtasks")!
    
    //  static let tasksRealmConfig                    = Realm.Configuration(syncConfiguration: SyncConfiguration(user: SyncUser.current!, realmURL:    tasksRealmURL),objectTypes: [TaskList.self, Task.self])
}

func commonRealmConfig(user: SyncUser) -> Realm.Configuration  {
    let config = Realm.Configuration(syncConfiguration: SyncConfiguration(user: SyncUser.current!, realmURL: Constants.commonRealmURL), objectTypes: [Person.self])
    return config
}

func tasksRealmConfig(user: SyncUser) -> Realm.Configuration  {
    let config = Realm.Configuration(syncConfiguration: SyncConfiguration(user: SyncUser.current!, realmURL: Constants.tasksRealmURL), objectTypes: [TaskList.self, Task.self])
    return config
}

// MARK: Model

final class TaskList: Object {
    @objc dynamic var text = ""
    @objc dynamic var id = ""
    let items = List<Task>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

final class Task: Object {
    @objc dynamic var text = ""
    @objc dynamic var completed = false
}

class Person : Object {
    @objc dynamic var id = ""
    @objc dynamic var creationDate: Date?
    @objc dynamic var lastUpdated: Date?
    
    @objc dynamic var lastName = ""
    @objc dynamic var firstName = ""
    
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func fullName() -> String {
        return "\(firstName) \(lastName)"
    }
    
    
    
    class func createProfile() -> Person? {
        let commomRealm =  try! Realm(configuration: commonRealmConfig(user: SyncUser.current!))
        var profileRecord = commomRealm.objects(Person.self).filter(NSPredicate(format: "id = %@", SyncUser.current!.identity!)).first
        if profileRecord == nil {
            try! commomRealm.write {
                profileRecord = commomRealm.create(Person.self, value:["id": SyncUser.current!.identity!, "creationDate": Date(),  "lastUpdated": Date()])
                commomRealm.add(profileRecord!, update: true)
            }
        }
        return profileRecord
    }
} // of Person
