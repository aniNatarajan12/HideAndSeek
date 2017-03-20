//
//  choosePlayer.swift
//  HideAndSeek
//
//  Created by Anirudh Natarajan on 3/19/17.
//  Copyright © 2017 Kodikos. All rights reserved.
//

import UIKit

class choosePlayer: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func hiderPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "hiderChosen", sender: self)
    }
    
    @IBAction func seekerPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "seekerChosen", sender: self)
    }
}
