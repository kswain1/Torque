//
//  StartUpViewController.swift
//  TestIos
//
//  Created by kehlin swain on 2/11/20.
//  Copyright © 2020 kehlin swain. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import FirebaseUI
import GoogleSignIn

class StartUpViewController: UIViewController {

    var authUI: FUIAuth!
    override func viewDidLoad() {
        super.viewDidLoad()
        authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if authUI.auth?.currentUser != nil {
            goToHomeScreen()
        } else {
            signIn()
        }
    }
    
    @IBAction func getStartedClicked( _ sender: Any){
        if authUI.auth?.currentUser != nil {
            self.goToHomeScreen()
        }else {
            self.signIn()
        }
    }
    
    @IBAction func getStartedClickedIsis( _ sender: Any){
        if authUI.auth?.currentUser != nil {
            self.goToHomeScreen()
        }else {
            self.signIn()
        }
    }
    
//    @IBAction func btnGetStartedClicked(_ sender: Any) {
//        if authUI.auth?.currentUser != nil {
//            goToHomeScreen()
//        } else {
//            signIn()
//        }
//    }
    
    //SIGN IN FUNCTION
    func signIn() {
        let providers: [FUIAuthProvider] = [
            FUIGoogleAuth(),
            FUIEmailAuth(),
            FUIAnonymousAuth()
        ]
        if authUI.auth?.currentUser == nil {
            self.authUI?.providers = providers
            present(authUI.authViewController(), animated: true, completion: nil)
        } else {
            goToHomeScreen()
        }
    }
    
    func goToHomeScreen() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        if let tabBarVC = self.storyboard?.instantiateViewController(withIdentifier: "MainController") as? UINavigationController {
            appDelegate?.window?.rootViewController = tabBarVC
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

//AUTHENTICATION EXTENSION

extension StartUpViewController: FUIAuthDelegate {
    
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String?
        if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            return true
        }
        // other URL handling goes here.
        return false
    }
    
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        // handle user and error as necessary
        if user != nil {
            goToHomeScreen()
        }
    }
    
    func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
        
        let loginViewController = FUIAuthPickerViewController(authUI: authUI)
        
        //loginViewController.view.backgroundColor = UIColor.black
        
        let logoFrame = CGRect(x: 0, y: 0, width: loginViewController.view.frame.size.width, height: loginViewController.view.frame.size.height)
        let logoImageView = UIImageView(frame: logoFrame)
        logoImageView.image = UIImage(named: "Splash Page")
        
       
        //fix this once Firebase UI releases the dark mode support for sign-in
        
//        loginViewController.view.subviews.backgroundColor = .white
//        loginViewController.view.subviews[0].subviews[0].backgroundColor = .white
        
        loginViewController.view.addSubview(logoImageView)
        loginViewController.view.sendSubviewToBack(logoImageView)
        return loginViewController
    }
    
}

