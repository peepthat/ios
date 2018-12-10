//
//  SettingsViewController.swift
//  Peep
//
//  Created by Regynald Augustin on 11/20/18.
//  Copyright © 2018 Regynald Augustin. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var endpointTextField: UITextField!
    @IBOutlet weak var addEndpointButton: UIButton!
    @IBOutlet weak var endpointPicker: UIPickerView!
    @IBOutlet weak var healthCheckButton: UIButton!
    @IBOutlet weak var healthCheckLabel: UILabel!
    
    var endpoints = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        endpointTextField.delegate = self
        
        endpointPicker.dataSource = self
        endpointPicker.delegate = self
        
        addEndpointButton.layer.cornerRadius = 8
        healthCheckButton.layer.cornerRadius = 8
        
        let tapDissmissGesutre: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapDissmissGesutre)
        
        guard let storedEndpoints =
            UserDefaults.standard.stringArray(forKey: Constants.EndpointsDefaultsKey) else {
                return
        }
        endpoints = storedEndpoints
        
        guard let activeEndpoint =
            UserDefaults.standard.value(forKey: Constants.ActiveEndpointDefaultsKey) as? String else { return }
        guard let index = endpoints.firstIndex(of: activeEndpoint) else { return }
        endpointPicker.selectRow(index, inComponent: 0, animated: false)
    }
    
    @IBAction func addEndpoint(_ sender: UIButton) {
        guard
            let text = endpointTextField.text,
            !text.isEmpty,
            let _ = URL(string: text)
            else { return }
        endpointTextField.text = ""
        endpoints.append(text)
        endpointPicker.reloadAllComponents()
        UserDefaults.standard.set(endpoints, forKey: Constants.EndpointsDefaultsKey)
    }
    
    @IBAction func testEndpoint(_ sender: Any) {
        if endpoints.count <= 0 { return }
        
        let selectedRow = endpointPicker.selectedRow(inComponent: 0)
        let activeEndpoint = endpoints[selectedRow]

        guard let url = URL(string: activeEndpoint) else { return }
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        DispatchQueue.main.async {
            self.healthCheckLabel.text = "Sending Request..."
        }
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("URL Session Task Succeeded: HTTP \(statusCode)")
                DispatchQueue.main.async {
                    guard let data = data else { return }
                    guard let payloadText = String(data: data, encoding: .utf8) else { return }
                    self.healthCheckLabel.text = "\(statusCode): \(payloadText)"
                }
            }
            else {
                // Failure
                print("URL Session Task Failed: %@", error!.localizedDescription);
                DispatchQueue.main.async {
                    self.healthCheckLabel.text = "Error! \(error!.localizedDescription)"
                }
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    @IBAction func clearEndpoints(_ sender: Any) {
        endpoints = []
        UserDefaults.standard.removeObject(forKey: Constants.EndpointsDefaultsKey)
        UserDefaults.standard.removeObject(forKey: Constants.ActiveEndpointDefaultsKey)
        endpointPicker.reloadAllComponents()
    }
    
    @objc func dismissKeyboard() {
        self.endpointTextField.endEditing(true)
    }
}

extension SettingsViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return endpoints.count
    }
}

extension SettingsViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return endpoints[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if endpoints.count > 0 {
            UserDefaults.standard.set(endpoints[row], forKey: Constants.ActiveEndpointDefaultsKey)
        }
    }
}

extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        addEndpoint(addEndpointButton)
        dismissKeyboard()
        return false
    }
}
