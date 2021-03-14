//
//  ViewController.swift
//  Project28_Keychain_touchFaceID
//
//  Created by iMac on 11.03.2021.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {
    @IBOutlet weak var secretTextView: UITextView!
    var rightBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveSecretMessage))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let notificationCenter = NotificationCenter.default
        //две нотификации потому что без первой Пол не отлавливал аппаратную клавиатуру:
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        //когда окно становится неактивно:
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
        
        title = "Nothing to see here"
        
    }
    
    //MARK: Actions -------------------------------------------------
    @IBAction func authenticateActionButton(_ sender: Any) {
        let ac = UIAlertController(title: "Choose authentication type", message: nil, preferredStyle: .actionSheet)
        
        ac.addAction(UIAlertAction(title: "Face ID", style: .default, handler: { [weak self] action in self?.biometryAuthentication() }))
        
        ac.addAction(UIAlertAction(title: "Password", style: .default, handler: { [weak self] action in self?.passwordAuthentification() }))
                     
        present(ac, animated: true)
    }
    
    func biometryAuthentication() {
        let context = LAContext()
        var error: NSError?
        
        //TOUCH ID:
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            
            let reason = "Identity yourself!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] (success, authenticationError) in
                
                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                    } else {
                        //error
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            //no biometry
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
    }
    
    func passwordAuthentification() {
        let ac = UIAlertController(title: "Enter password", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        if let text = KeychainWrapper.standard.string(forKey: "password") {
            ac.textFields?.first?.text = text
        }
        
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak ac, weak self] (action) in
            if let text = ac?.textFields?.first?.text {
                if text == "lol" {
                    KeychainWrapper.standard.set(text, forKey: "password")
                    self?.unlockSecretMessage()
                } 
            }
        }))
        
        present(ac, animated: true)
    }
    
    //MARK: Functions -----------------------------------------------
    //чтобы клавиатура была ниже вводимого текста:
    @objc func adjustForKeyboard(notification: Notification) {
        
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame   = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            secretTextView.contentInset = .zero
        } else {
            secretTextView.contentInset = UIEdgeInsets(top: 0, left: 0,
                                                       bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        secretTextView.scrollIndicatorInsets = secretTextView.contentInset
        
        let selectedRange = secretTextView.selectedRange
        secretTextView.scrollRangeToVisible(selectedRange)
        
       
        
    }
    
    func unlockSecretMessage() {
        secretTextView.isHidden = false
        title = "Secret stuff!"
        
        if let text = KeychainWrapper.standard.string(forKey: "SecretMessage") {
            secretTextView.text = text
            navigationItem.rightBarButtonItem = rightBarButton
        }
    }
    
    @objc func saveSecretMessage() {
        
        guard secretTextView.isHidden == false else { return }
        
        KeychainWrapper.standard.set(secretTextView.text, forKey: "SecretMessage")
        navigationItem.rightBarButtonItem = nil
        secretTextView.resignFirstResponder()
        secretTextView.isHidden = true
        title = "Nothing to see here"
    }


}

