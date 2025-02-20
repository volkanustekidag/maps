//
//  ListViewController.swift
//  maps_app
//
//  Created by Volkan Ustekidag on 16.02.2025.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
    
    
    @IBOutlet weak var tableView: UITableView!
    var titles =  [String]()
    var ids = [UUID]()
    
    var selectedTitle = ""
    var selectedId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        navigationController?.navigationBar.topItem?.title = "Location List"
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onClickAdd))
        print("a b c")
        getLocations()
        
    }
    
    
    @objc func getLocations() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest =  NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        fetchRequest.returnsObjectsAsFaults = false
        
        
        do {
            let locations = try context.fetch(fetchRequest)
            
            titles.removeAll(keepingCapacity: false)
            ids.removeAll(keepingCapacity: false)
            
            if locations.count > 0 {
                for someLocation in locations as! [NSManagedObject] {
                    
                    if let title = someLocation.value(forKey: "title") as? String {
                        titles.append(title)
                    }
                    
                    if let id = someLocation.value(forKey: "id") as? UUID {
                        ids.append(id)
                    }
                    
                }
                
                tableView.reloadData()
            }
        } catch {
            
        }
    }
    
    @objc func onClickAdd() {
        selectedTitle = ""
        performSegue(withIdentifier: "toMapVC", sender: nil )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(getLocations), name: NSNotification.Name( "newLocationSaved"), object: nil)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.textLabel?.text = titles[indexPath.row]
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedId = ids[indexPath.row]
        selectedTitle = titles[indexPath.row]
        performSegue(withIdentifier: "toMapVC", sender: nil )
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapVC" {
            if let destinationVC = segue.destination as? MapViewController {
                destinationVC.selectedId = selectedId
                destinationVC.selectedTitle = selectedTitle
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let uuidToDelete = ids[indexPath.row]
            deleteData(uuidStr: uuidToDelete.uuidString,indexPath: indexPath)
            
        }
    }
    
    
    func deleteData(uuidStr: String,indexPath:IndexPath) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Location")
        fetchRequest.predicate = NSPredicate(format: "id == %@", uuidStr)
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let responses = try context.fetch(fetchRequest)
            if responses.count > 0 {
                for val in responses as! [NSManagedObject] {
                    if let id = val.value(forKey: "id") as? UUID {
                        if id == ids[indexPath.row] {
                            context.delete(val)
                            ids.remove(at: indexPath.row)
                            titles.remove(at: indexPath.row)
                            self.tableView.reloadData()
                            
                            do {
                                try  context.save()
                            } catch {
                                print("Failed to save")
                            }
                            break
                        }
                    }
                }
            }
        } catch {
            print("Failed to delete")
        }
    }
}
