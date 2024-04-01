//
//  ListViewController.swift
//  TravelBook3
//
//  Created by Ömer Yılmaz on 4.01.2024.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate,UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var titleArray = [String]()
    var idArray = [UUID]()
    var chosenTitle = ""
    var chosenTitleID : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
            
        tableView.delegate = self
        tableView.dataSource = self
        getData()
    }
    
    @objc func getData() {
        // Uygulamanın AppDelegate'ine erişim sağlanıyor.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        // Core Data işlemleri için kullanılacak bağlam (context) oluşturuluyor.
        let context = appDelegate.persistentContainer.viewContext

        // "Places" adlı Core Data varlığı üzerinde sorgu oluşturuluyor.
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")

        // Nesnelerin tamamen yüklenmiş olmasını sağlamak için returnsObjectsAsFaults özelliği false olarak ayarlanıyor.
        request.returnsObjectsAsFaults = false
        do{
            let results = try context.fetch(request)
            
            if results.count > 0 {
                self.titleArray.removeAll(keepingCapacity: false)
                self.idArray.removeAll(keepingCapacity: false)
                for result in results as! [NSManagedObject]{
                    if let title = result.value(forKey: "title") as? String{
                        self.titleArray.append(title)
                    }
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idArray.append(id)
                    }
                    tableView.reloadData()
                }
            }
        }catch{
            print("Error")
        }
    }
    
    // ViewController'ın view'i ekranda görünmeye başlamadan önce gerçekleşir
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name(rawValue: "newPlace"), object: nil)// addObserver bir gözlemci ekleme komutudur
    }

    
    @objc func addButtonClicked(){
        chosenTitle = ""
        performSegue(withIdentifier: "toViewConroller", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row]
        return cell
    }
    
    //Kullanıcı bir tabloya dokunduğunda veya bir hücreye dokunduğunda çağrılır
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = titleArray[indexPath.row]
        chosenTitleID = idArray[indexPath.row]
        performSegue(withIdentifier: "toViewConroller", sender: nil)
    }
    
    //Bir segue (geçiş) gerçekleşmeden önce yapılması gereken hazırlık işlemlerini tanımlamak için kullanılır
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toViewConroller"{
            let destinationVC = segue.destination as! ViewController
            destinationVC.selectedTitle = chosenTitle
            destinationVC.selectedTitleID = chosenTitleID
        }
    }
}
