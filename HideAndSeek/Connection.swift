//
//  Connection.swift
//  HideAndSeek
//
//  Created by Anirudh Natarajan on 3/19/17.
//  Copyright © 2017 Kodikos. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class Connection: UIViewController, MCBrowserViewControllerDelegate {
    
    var appDelegate:AppDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.mpcHandler.setupPeerWithDisplayName(UIDevice.current.name)
        appDelegate.mpcHandler.setupSession()
        appDelegate.mpcHandler.advertiseSelf(true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(Connection.peerChangedStateWithNotification(_:)), name: NSNotification.Name(rawValue: "MPC_DidChangeStateNotification"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.navigationItem.title == "Connected" {
            print("connected")
            self.performSegue(withIdentifier: "playerConnected", sender: self)
        }
    }
    
    @IBAction func connectClicked(_ sender: Any) {
        if appDelegate.mpcHandler.session != nil{
            appDelegate.mpcHandler.setupBrowser()
            appDelegate.mpcHandler.browser.delegate = self
            
            self.present(appDelegate.mpcHandler.browser, animated: true, completion: nil)
            
        }
    }
    
    func peerChangedStateWithNotification(_ notification:Notification){
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        
        let state = userInfo.object(forKey: "state") as! Int
        
        if state != MCSessionState.connecting.rawValue{
            self.navigationItem.title = "Connected"
        }
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController!) {
        appDelegate.mpcHandler.browser.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController!) {
        appDelegate.mpcHandler.browser.dismiss(animated: true, completion: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
}
