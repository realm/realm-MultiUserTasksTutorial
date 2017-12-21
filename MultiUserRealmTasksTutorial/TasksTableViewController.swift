//
//  TasksTableViewController.swift
//  MultiUserRealmTasksTutorial
//
//  Created by Ian Ward on 12/20/17.
//  Copyright © 2017 Ian Ward. All rights reserved.
//

import UIKit
import RealmSwift

class TasksTableViewController: UITableViewController {
    var realm:          Realm!
    var items:          List<Task>?         // all of the tasks
    var myTaskLists:    Results<TaskList>?  // all tasks lists
    var currentTaskList: TaskList?          // the current list we're watching
    
    var notificationToken: NotificationToken!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRealm()
        
        // if the tssk list is empty, make a new task so the user sees something on launch.
        if (items?.count == 0 ) {
            try! realm.write {
                let values =  ["text": "My First Task"]
                let newTask = realm.create(Task.self, value: values)
                realm.add(newTask) // add the new tasks
                self.currentTaskList?.items.append(newTask) // and add it to our default list
            } // of write
        } // of empty items check
        
    } // of viewDidLoad
    
    func setupUI() {
        title = "My Tasks"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        // we don't have a UINavigationController so let's add a hand-constructed UINavBar
        let screenSize: CGRect = UIScreen.main.bounds
        let navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 44))
        let navItem = UINavigationItem(title: "")
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
        let logoutButton = UIBarButtonItem(title: NSLocalizedString("Logout", comment:"logout"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(handleLogout))
        navItem.rightBarButtonItems =  [addButton, logoutButton]
        navItem.leftBarButtonItem = editButtonItem
        navBar.setItems([navItem], animated: false)
        
        self.view.addSubview(navBar)
    }
    
    
    
    func setupRealm() {
        // Open the Realm, if necessary - it's probably been passed in to us
        // by the login mechanism which did an realm.asyncOpen()
        if self.realm == nil {
            self.realm = try! Realm(configuration: tasksRealmConfig(user: SyncUser.current!))
        }
        
        // Next, let's get all of our task lists, and then we'll set the default to the first one
        // (of course if there are not, in fact, any taks lists, we'll make one)
        self.myTaskLists = self.realm.objects(TaskList.self)
        if self.myTaskLists!.count > 0 {
            self.currentTaskList = self.myTaskLists!.first
        } else {
            try! realm.write {
                let initialValues = ["id": NSUUID().uuidString, "text": "My First Task List"]
                let newTaskList = realm.create(TaskList.self, value: initialValues)
                self.currentTaskList = newTaskList
            }
        }
        
        
        // Now, get all of our tasks, if any.  On return, we'll check to see if the list is empty
        // and make a prototype 1st task for the user so they're not looking ast a blank screen.
        items = self.currentTaskList?.items // NB: this will return an empty list if there are no tasks
        
        // and, finally, let's listen for changes to the task list object
        self.notificationToken = self.setupNotifications()

    }// of setupRealm
    
    
    func setupNotifications() -> NotificationToken? {
        return self.currentTaskList?.items.observe { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
                                     with: .automatic)
                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.endUpdates()
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
    } // of setupNotifications
    
    
    
//    func SavedsetupRealm() {
//        DispatchQueue.main.async {
//            // Open Realm
//            self.realm = try! Realm(configuration: tasksRealmConfig(user: SyncUser.current!))
//
//            // Show initial tasks
//            func updateList() {
//                if self.items.realm == nil, let list = self.realm.objects(TaskList.self).first {
//                    self.items = list.items
//                }
//                self.tableView.reloadData()
//            }
//            updateList()
//
//            // Notify us when Realm changes
//            self.notificationToken = self.realm.observe { _,_ in
//                updateList()
//            }
//        } // of Dispatch...main
//    }// of setupRealm
    
    
    deinit {
        notificationToken?.invalidate()
    }
    
    
    
    
    // MARK: Turn off the staus bar
    
    open override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // MARK: UITableView
   override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return self.currentTaskList?.items.count ?? 0
    }
    
//    override func tableView(_ tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
//        return self.currentTaskList?.items.count ?? 0
//    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = items![indexPath.row]
        cell.textLabel?.text = item.text
        cell.textLabel?.alpha = item.completed ? 0.5 : 1
        return cell
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        try! items?.realm?.write {
            items?.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            try! realm.write {
                let item = items?[indexPath.row]
                realm.delete(item!)
            }
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items![indexPath.row]
        try! item.realm?.write {
            item.completed = !item.completed
            let destinationIndexPath: IndexPath
            if item.completed {
                // move cell to bottom
                destinationIndexPath = IndexPath(row: items!.count - 1, section: 0)
            } else {
                // move cell just above the first completed item
                let completedCount = items!.filter("completed = true").count
                destinationIndexPath = IndexPath(row: items!.count - completedCount - 1, section: 0)
            }
            items!.move(from: indexPath.row, to: destinationIndexPath.row)
        }
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    
    // MARK: Functions
    
    @objc func add() {
        let alertController = UIAlertController(title: "New Task", message: "Enter Task Name", preferredStyle: .alert)
        var alertTextField: UITextField!
        alertController.addTextField { textField in
            alertTextField = textField
            textField.placeholder = "Task Name"
        }
        alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            guard let text = alertTextField.text , !text.isEmpty else { return }
            
            let items = self.items
            try! items?.realm?.write {
                items!.insert(Task(value: ["text": text]), at: items!.filter("completed = false").count)
            }
        })
        present(alertController, animated: true, completion: nil)
    }
    
    // Logout Support
    
    
    @IBAction  func handleLogout(sender:AnyObject?) {
        let alert = UIAlertController(title: NSLocalizedString("Logout", comment: "Logout"), message: NSLocalizedString("Really Log Out?", comment: "Really Log Out?"), preferredStyle: .alert)
        
        // Logout button
        let OKAction = UIAlertAction(title: NSLocalizedString("Logout", comment: "logout"), style: .default) { (action:UIAlertAction!) in
            SyncUser.current?.logOut()
            self.navigationController?.setViewControllers([TasksLoginViewController()], animated: true)
        }
        alert.addAction(OKAction)
        
        // Cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction!) in
            print("Cancel button tapped");
        }
        alert.addAction(cancelAction)
        
        // Present Dialog message
        present(alert, animated: true, completion:nil)
    }
}
