//
//  ResultsViewController.swift
//  Peep
//
//  Created by Regynald Augustin on 11/24/18.
//  Copyright © 2018 Regynald Augustin. All rights reserved.
//

import AVFoundation
import UIKit

class ResultsViewController: UIViewController {

    var capturedImage: UIImage!
    var activeEndpoint: String = ""
    
    @IBOutlet weak var capturedImageView: UIImageView!
    @IBOutlet weak var encodingToggle: UISegmentedControl!
    @IBOutlet weak var endpointLabel: UILabel!
    @IBOutlet weak var resultsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        capturedImageView.image = capturedImage
        capturedImageView.contentMode = .scaleAspectFit
        
        guard let stored = UserDefaults.standard.value(forKey: Constants.ActiveEndpointDefaultsKey) as? String else {
            endpointLabel.text = "~~ no endpoint set ~~"
            return
        }
        activeEndpoint = stored
        endpointLabel.text = "Sending to: \(activeEndpoint)"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard let stored = UserDefaults.standard.value(forKey: Constants.ActiveEndpointDefaultsKey) as? String else {
            endpointLabel.text = "~~ no endpoint set ~~"
            return
        }
        activeEndpoint = stored
        DispatchQueue.main.async {
            self.endpointLabel.text = "Sending to: \(self.activeEndpoint)"
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func sendRequest(_ sender: Any) {
        let imageData: Data?
        let contentType: String
        
        switch encodingToggle.selectedSegmentIndex {
        case 0:
            imageData = capturedImage.pngData()
            contentType = "image/png"
        case 1:
            imageData = capturedImage.jpegData(compressionQuality: 0.95)
            contentType = "image/jpeg"
        default:
            print("Invalid case")
            return
        }
        
        createRequest(imageData: imageData, contentType: contentType)
    }
    
    func createRequest(imageData: Data?, contentType: String) {
        guard imageData != nil,
            let url = URL(string: activeEndpoint) else { return }

        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData

        DispatchQueue.main.async {
            self.resultsLabel.text = "Sending Request..."
        }

        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("URL Session Task Succeeded: HTTP \(statusCode)")
                DispatchQueue.main.async {
                    guard let data = data else { return }
                    guard let payloadText = String(data: data, encoding: .utf8) else { return }
                    self.resultsLabel.text = "\(statusCode): \(payloadText)"
                }
            }
            else {
                // Failure
                print("URL Session Task Failed: %@", error!.localizedDescription);
                DispatchQueue.main.async {
                    self.resultsLabel.text = "Error! \(error!.localizedDescription)"
                }
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
}
