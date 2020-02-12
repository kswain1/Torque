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


class FireViewController: UIViewController {

    var db: Firestore!

    override func viewDidLoad() {
        super.viewDidLoad()

        // [START setup]
        let settings = FirestoreSettings()

        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        self.getCollection()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
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

}
