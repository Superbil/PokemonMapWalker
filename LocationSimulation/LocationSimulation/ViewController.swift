//
//  ViewController.swift
//  LocationSimulation
//
//  Created by Brian Wang on 8/7/16.
//  Copyright © 2016 MapWalker. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private weak var actionButton: UIButton! {
        didSet {
            actionButton.addTarget(self, action: #selector(selectAction(_:)), for: .touchUpInside)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        debugPrint("Receive Memory Warning")
    }

    @objc func selectAction(_ sender: UIButton) {
        let c = UIAlertController(title: "Select map app",
                                  message: nil,
                                  preferredStyle: .actionSheet)
        let appleMapURL = URL(string: "http://maps.apple.com/maps?")!
        if UIApplication.shared.canOpenURL(appleMapURL) {
            c.addAction(UIAlertAction(title: "Apple Map", style: .default, handler: { _ in
                UIApplication.shared.openURL(appleMapURL)
            }))
        }
        let googleMapURL = URL(string: "comgooglemaps://?")!
        if UIApplication.shared.canOpenURL(googleMapURL) {
            c.addAction(UIAlertAction(title: "Google Map", style: .default, handler: { action in
                UIApplication.shared.openURL(googleMapURL)
            }))
        }
        c.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(c, animated: true)
    }
}

