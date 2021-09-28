//
//  ViewController.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
    }
    
    private func configureUI() {
        navigationItem.title = "Real-Time Communications"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        view.backgroundColor = UIColor.systemBackground
    }

}
