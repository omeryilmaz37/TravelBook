//
//  ViewController.swift
//  TravelBook3
//
//  Created by Ömer Yılmaz on 4.01.2024.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager() // Konum tabanlı hizmetleri yönetmek ve kullanıcının konumunu almak için kullanılır.
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest// Konumun verisi ne kadar keskinlikle bulunacak
        locationManager.requestWhenInUseAuthorization()// Benim app'i mi kullanırken kullanıcıdan izin iste
        locationManager.startUpdatingLocation()// Kullanıcının konumunu almaya başlıyorum
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2 // Ekrana ne kadar süre basılı tutması gerekiyor
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedTitle != "" {
            //Core Data
            // Uygulamanın AppDelegate'ine erişim sağlanıyor.
            let appDelegate = UIApplication.shared.delegate as! AppDelegate

            // Core Data işlemleri için kullanılacak bağlam (context) oluşturuluyor.
            let context = appDelegate.persistentContainer.viewContext

            // "Places" adlı Core Data varlığı üzerinde sorgu oluşturuluyor.
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")

            // Seçilen başlığın (title) ID'si alınıyor ve string formatına dönüştürülüyor.
            let idString = selectedTitleID!.uuidString

            // Oluşturulan sorguya bir filtre (predicate) ekleniyor. Bu filtre, sadece belirli bir ID'ye sahip veriyi çekmek için kullanılır.
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)

            // Nesnelerin tamamen yüklenmiş olmasını sağlamak için returnsObjectsAsFaults özelliği false olarak ayarlanıyor.
            fetchRequest.returnsObjectsAsFaults = false
            do{
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                annotationSubtitle = subtitle
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                     annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                         annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta:  0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                    }
                                }
                            }
                        }
                    }
                }
            }catch{
                print("Error")
            }
        }else{
            //Add New Data
        }
    }

    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer){
        // Ekrana basılı tutulduktan sonra ne işlem yapılsın
        
        // Eğer kullanıcı basılı tutma hareketini başlattıysa
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: self.mapView) // Dokunulan noktayı al
            let touchedCoordinate = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView) // Dokunulan noktanın koordinatını harita koordinatlarına çevir
            
            chosenLatitude = touchedCoordinate.latitude
            chosenLongitude = touchedCoordinate.longitude
            
            let annotation = MKPointAnnotation() // Yeni bir MKPointAnnotation oluştur
            annotation.coordinate = touchedCoordinate //Annotasyonun koordinatını belirleme.
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            
            // Haritaya bu yeni annotasyonu ekle
            self.mapView.addAnnotation(annotation)//Oluşturulan annotasyonu haritaya ekleyerek gösterme.
        }
        mapView.isUserInteractionEnabled = true
    }

    // Güncellenen lokasyonları bize bir dizi içerisinde veriyor
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == ""{
            // Enlem ve boylam bilgilerini giricez
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            // Zoomlamak için bu komutu kullanıyoruz
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }else{
            
        }
    }

    // Harita görünümü için özel bir işaret görünümü oluşturan fonksiyon
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Eğer işaret MKUserLocation (kullanıcının konumu) ise, nil döndür ve özel bir görünüm oluşturulmasını engelle
        if annotation is MKUserLocation {
            return nil
        }
        
        // İşaretin tekrar kullanılabilir bir kimliği (ID) var mı kontrol et
        var reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        // Eğer pinView boşsa (tekrar kullanılabilir kimlik bulunamazsa), yeni bir MKPinAnnotationView oluştur
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true // İşaretin bilgi balonunu göstermesine izin ver
            pinView?.tintColor = UIColor.black // İşaret rengini siyah olarak ayarla
            
            // Sağ üst köşede bilgi balonunu açacak bir detay düğmesi (button) ekle
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            // Eğer pinView tekrar kullanılabilirse, mevcut pinView'i güncelle
            pinView?.annotation = annotation
        }
        
        // Oluşturulan veya güncellenen pinView'i döndür
        return pinView
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            var requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                // closure
                
                if let placemark = placemarks {
                    if placemark .count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeDefault:MKLaunchOptionsDirectionsModeDriving ]
                        item.openInMaps(launchOptions: launchOptions )
                    }
                }
            }
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("SUCCESS")
        }catch{
            print("ERROR")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)//Noticaciton kullanarak viewController arasında mesajlar yollayabilirsiniz
        self.navigationController?.popViewController(animated: true)
    }
    

}

