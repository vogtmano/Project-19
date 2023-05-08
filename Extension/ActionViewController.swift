//
//  ActionViewController.swift
//  Extension
//
//  Created by Maks Vogtman on 24/01/2023.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {
    @IBOutlet var script: UITextView!
    var pageTitle = ""
    var pageURL = ""
    var savedScriptsByURL = [String: String]()
    var savedScriptsByURLKey = "savedScriptsByURL"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(done))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "List", style: .plain, target: self, action: #selector(scriptList))
        navigationItem.rightBarButtonItem?.isEnabled = true
        navigationItem.leftBarButtonItem?.isEnabled = true
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    
        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = inputItem.attachments?.first {
                itemProvider.loadItem(forTypeIdentifier: kUTTypePropertyList as String) { [weak self] (dict, error) in
                    guard let itemDictionary = dict as? NSDictionary else { return }
                    guard let javaScriptValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else { return }
                    self?.pageTitle = javaScriptValues["title"] as? String ?? ""
                    self?.pageURL = javaScriptValues["URL"] as? String ?? ""
                    self?.loadData()
                    
                    DispatchQueue.main.async {
                        self?.title = self?.pageTitle
                        self?.updateUI()
                    }
                }
            }
        }
    }
    
    
    func loadData() {
        let defaults = UserDefaults.standard
        savedScriptsByURL = defaults.object(forKey: savedScriptsByURLKey) as? [String: String] ?? [String: String]()
    }
    
    
    func updateUI() {
        if let url = URL(string: pageURL) {
            if let host = url.host() {
                script.text = savedScriptsByURL[host]
            }
        }
    }
    
    
    func saveScriptForCurrentURL() {
        if let url = URL(string: pageURL) {
            if let host = url.host() {
                script.text = savedScriptsByURL[host]
            }
        }
        
        let defaults = UserDefaults.standard
        defaults.set(savedScriptsByURL, forKey: savedScriptsByURLKey)
    }

    
    @IBAction func done() {
        DispatchQueue.global().async { [weak self] in
            self?.saveScriptForCurrentURL()
            
            let item = NSExtensionItem()
            let argument: NSDictionary = ["customJavaScript": self?.script.text as Any]
            let webDictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: argument]
            let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: kUTTypePropertyList as String)
            item.attachments = [customJavaScript]
            
            DispatchQueue.main.async {
                self?.extensionContext?.completeRequest(returningItems: [item])
            }
        }
    }
    
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            script.contentInset = .zero
        } else {
            script.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        script.scrollIndicatorInsets = script.contentInset
        
        let selectedRange = script.selectedRange
        script.scrollRangeToVisible(selectedRange)
    }
    
    
    @objc func scriptList() {
        let ac = UIAlertController(title: "Script List", message: "Choose a script", preferredStyle: .alert)
        
        ac.addAction(UIAlertAction(title: "alert(document.title);", style: .default, handler: { action in
            self.script.text = action.title
        }))
        ac.addAction(UIAlertAction(title: "alert(document.URL);", style: .default, handler: { action in
            self.script.text = action.title
        }))
        
        present(ac, animated: true)
    }
}
