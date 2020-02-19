//
//  FireViewController.swift
//  TestIos
//
//  Created by kehlin swain on 2/12/20.
//  Copyright © 2020 kehlin swain. All rights reserved.
//

import Foundation
import UIKit

import FirebaseCore
import FirebaseFirestore


class FireViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    var db: Firestore!

    override func viewDidLoad() {
        super.viewDidLoad()

        // [START setup]
        let settings = FirestoreSettings()

        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
   
//    func setupTableView() {
//        tableview.delegate = self
//        tableview.dataSource = self
//
//    }
    
    private func getCollection() {
          // [START get_collection]
          db.collection("organization").getDocuments() { (querySnapshot, err) in
              if let err = err {
                  print("Error getting documents: \(err)")
              } else {
                  for document in querySnapshot!.documents {
                      print("\(document.documentID) => \(document.data())")
                  }
              }
          }
          // [END get_collection]
      }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            self.getCollection()
            return 4

       }

       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: <#T##String#>, for: <#T##IndexPath#>)
                var organizations: UITableViewCell!
                //var label:UILabel = "hello"
               organizations.textLabel!.text = "hello"
                return organizations
       }
       

}
