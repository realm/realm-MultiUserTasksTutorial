//
//  TasksTableViewController.swift
//  MultiUserRealmTasksTutorial
//
//  Created by David Spector on 6/6/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import UIKit
import RealmSwift

class TasksTableViewController: UITableViewController,  UIGestureRecognizerDelegate  {
    var realm: Realm!
    var notificationToken: NotificationToken!
    var items = List<Task>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupRealm()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    
    
    // MARK: - Realm Specific Code
    
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
        DispatchQueue.main.async {
            // Open Realm
            self.realm = try! Realm(configuration: Constants.tasksRealmConfig)
            
            // Show initial tasks
            func updateList() {
                if self.items.realm == nil, let list = self.realm.objects(TaskList.self).first {
                    self.items = list.items
                }
                self.tableView.reloadData()
            }
            updateList()
            
            // Notify us when Realm changes
            self.notificationToken = self.realm.addNotificationBlock { _ in
                updateList()
            }
        }
    }

    
    func add() {
        let alertController = UIAlertController(title: NSLocalizedString("New Task", comment:"New Task"), message: NSLocalizedString("Enter Task Name", comment:"task name"), preferredStyle: .alert)
        var alertTextField: UITextField!
        alertController.addTextField { textField in
            alertTextField = textField
            textField.placeholder = NSLocalizedString("Task Name", comment:"task name")
        }
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Add", comment:"Add"), style: .default) { _ in
            guard let text = alertTextField.text , !text.isEmpty else { return }
            
            let items = self.items
            try! items.realm?.write {
                items.insert(Task(value: ["text": text]), at: items.filter("completed = false").count)
            }
        })
        present(alertController, animated: true, completion: nil)
    }

    
    
    
    @IBAction  func handleLogout(sender:AnyObject?) {
        let alert = UIAlertController(title: NSLocalizedString("Logout", comment: "Logout"), message: NSLocalizedString("Really Log Out?", comment: "Really Log Out?"), preferredStyle: .alert)
        
        // Logout button
        let OKAction = UIAlertAction(title: NSLocalizedString("Logout", comment: "logout"), style: .default) { (action:UIAlertAction!) in
            SyncUser.current?.logOut()
            //Now we need to segue to the login view controller
            self.performSegue(withIdentifier: Constants.kExitToLoginViewSegue, sender: self)
        }
        alert.addAction(OKAction)
        
        // Cancel button
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment:"cancel"), style: .cancel) { (action:UIAlertAction!) in
            print("Cancel button tapped");
        }
        alert.addAction(cancelAction)
        
        // Present Dialog message
        present(alert, animated: true, completion:nil)
    }

    
    
    // MARK: Turn off the staus bar
    
    open override var prefersStatusBarHidden : Bool {
        return true
    }

    
    // MARK: - Table view Data Source Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    // MARK: - UITableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        try! item.realm?.write {
            item.completed = !item.completed
            let destinationIndexPath: IndexPath
            if item.completed {
                // move cell to bottom
                destinationIndexPath = IndexPath(row: items.count - 1, section: 0)
            } else {
                // move cell just above the first completed item
                let completedCount = items.filter("completed = true").count
                destinationIndexPath = IndexPath(row: items.count - completedCount - 1, section: 0)
            }
            items.move(from: indexPath.row, to: destinationIndexPath.row)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = items[indexPath.row]
        cell.textLabel?.text = item.text
        cell.textLabel?.alpha = item.completed ? 0.5 : 1
        return cell
    }

    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        try! items.realm?.write {
            items.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            try! realm.write {
                let item = items[indexPath.row]
                realm.delete(item)
            }
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */


    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
