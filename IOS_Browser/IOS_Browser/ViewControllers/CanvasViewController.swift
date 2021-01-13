//
//  CanvasViewController.swift
//  WebBroser
//
//  Created by user183363 on 1/11/21.
//

import UIKit
import WebKit
import RealmSwift

let BookMarksIdentifier = "Bookmarks"
let TabsIdentifier = "Tabs"

class CanvasViewController: UIViewController, WKNavigationDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var canvasView: UIView!

    var currentWebView : WKWebView!
    var errorView : UIView = UIView()
    var errorLabel : UILabel  = UILabel()
    var bookmarks: [Bookmark] = [Bookmark]()
    var tabs: [Tab] = [Tab]()
    var webviews: [WKWebView] = [WKWebView]()
    var selectedTab: Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LoadBookmark()
        LoadTabs()
        ConfigureSearchBar()
        ConfigureErrors()
        LoadWebViews()
    }
    
    //Configuration methods
    
    func ConfigureSearchBar() {
        searchBar.delegate = self
    }
    
    func ConfigureWebView() -> WKWebView {
        let webConfig = WKWebViewConfiguration()
        let frame = CGRect(x: 0.0, y: 0.0, width: canvasView.frame.width, height: canvasView.frame.height)
        let webview = WKWebView(frame: frame, configuration: webConfig)
        webview.navigationDelegate = self
        return webview
    }
    
    func ConfigureErrors() {
        var frame = CGRect(x: 0.0, y: 0.0, width: canvasView.frame.width, height: canvasView.frame.height)
        errorView = UIView(frame: frame)
        errorView.backgroundColor = UIColor.white
        
        frame = CGRect(x: 0.0, y: 0.0, width: frame.size.width, height: frame.size.height)
        errorLabel = UILabel(frame: frame)
        errorLabel.backgroundColor = UIColor.white
        errorLabel.textColor = UIColor.pastelGrayColor()
        errorLabel.text = ""
        errorLabel.textAlignment = .center
        errorLabel.font = UIFont(name: "HelveticaNeue", size: 25)
        errorLabel.numberOfLines = 0
    }
    
    func LoadBookmark() {
        let realm = try! Realm()
        let results = realm.objects(Bookmark.self)
        bookmarks.removeAll()
        for item in results {
            bookmarks.append(item)
        }
    }
    
    func LoadTabs() {
        let realm = try! Realm()
        let results = realm.objects(Tab.self)
        for item in results {
            webviews.append(ConfigureWebView())
            tabs.append(item)
        }
        selectedTab = 0
    }
    
    func LoadWebViews() {
        currentWebView?.removeFromSuperview()
        currentWebView = webviews[selectedTab]
        canvasView.addSubview(currentWebView)
        
        if currentWebView.url == nil && !tabs[selectedTab].url.isEmpty {
            loadWebSite(tabs[selectedTab].url, true, true)
        }else{
            searchBar.text = currentWebView.url?.absoluteString
        }
        UpdateToolBarButtons()
    }
    
    //web methods
    
    func loadWebSite(_ input: String, _ isURLDomain: Bool, _ isURLPreprocessed: Bool) {
        var encodedURL: String = input
        if !isURLPreprocessed {
            if isURLDomain {
                if (encodedURL.starts(with: "http://")){
                    encodedURL = String(encodedURL.dropFirst(7))
                }else if (encodedURL.starts(with: "https://")){
                    encodedURL = String(encodedURL.dropFirst(8))
                }
                encodedURL = "https://" + encodedURL.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                
            }else{
                encodedURL = "https://www.bing.com/search?dcr=0&q=" + encodedURL.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            }
        }
        
        let url: URL = URL(string: "\(encodedURL)")!
        let request: URLRequest = URLRequest(url: url)
        currentWebView.load(request)
        HideError()
        searchBar.text = encodedURL.lowercased()
        let tab: Tab = tabs[selectedTab]
        let realm = try! Realm()
        try! realm.write {
            tab.initialURL = encodedURL.lowercased()
        }
    }
    
    func displayError(_ info: String) {
        errorLabel.text = info
        canvasView.addSubview(errorView)
        canvasView.addSubview(errorLabel)
        
    }
    
    func HideError() {
        errorView.removeFromSuperview()
        errorLabel.removeFromSuperview()
    }
    
    //WKnavigation method
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation) {
        print("Commited")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        print("Finished")
        UpdateToolBarButtons()
        let tab = tabs[selectedTab]
        let realm = try! Realm()
        try! realm.write{
            tab.title = currentWebView.title!
            tab.url = (currentWebView.url?.absoluteString)!
        }
        
        
    }
    
    func webView(_ webview: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        print("Started Provisional Navigation")
    }
    
    func webView(_ webview: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        displayError(error.localizedDescription)
        UpdateToolBarButtons()
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let cred = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, cred)
    }
    
    //UISearchar delagate methods
    
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        
        let alertViewController: UIAlertController = UIAlertController(title: "", message: "Bookmark added", preferredStyle: UIAlertController.Style.alert)
        
        let alrtAction:UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        
        alertViewController.addAction(alrtAction)
        
        if let url = currentWebView.url?.absoluteString {
            print(url)
            let realm = try! Realm()
            let newBookmark = Bookmark(value: ["url": url, "title": currentWebView.title!])
            try! realm.write{
                realm.add(newBookmark, update: .all)
            }
            LoadBookmark()
        }
        present(alertViewController, animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        let input: String = (searchBar.text?.trimmingCharacters(in: .whitespaces))!
        if (!input.isEmpty) {
            if (input.hasSuffix(".com") || input.hasSuffix(".com/")){
                loadWebSite(input, true, false)
            }else{
                loadWebSite(input, false, false)
            }
            
        }
    }
    
    //Toolbar methods

    @IBAction func goForward(_ sender: UIBarButtonItem) {
        currentWebView.goForward()
        HideError()
        searchBar.text = currentWebView.url?.absoluteString
    }
    @IBAction func goBack(_ sender: UIBarButtonItem) {
        
        if (errorView.isDescendant(of: canvasView)) {
            HideError()
        }else{
            currentWebView.goBack()
        }
        searchBar.text = currentWebView.url?.absoluteString
    }
    @IBAction func Reload(_ sender: UIBarButtonItem) {
        currentWebView.reload()
    }
    
    func UpdateToolBarButtons() {
        if currentWebView.canGoForward {
            forwardButton.isEnabled = true
        }else {
            forwardButton.isEnabled = false
        }
        
        if currentWebView.canGoBack {
            backButton.isEnabled = true
        }else {
            backButton.isEnabled = false
        }
    }
    
    func delagate(_ tab: Tab, _ tabIndex: Int){
        let realm = try! Realm()
        try! realm.write{
            realm.delete(tab)
        }
        tabs.remove(at: tabIndex)
        webviews.remove(at: tabIndex)
        if selectedTab == tabIndex {
            selectedTab = tabIndex - 1
            LoadWebViews()
            navigationController?.popViewController(animated: true)
        }else if selectedTab > tabIndex {
            selectedTab = selectedTab - 1
        }
    }
    
    func addTab(_ tab: Tab) {
        tabs.append(tab)
        selectedTab = tabs.count - 1
        webviews.append(ConfigureWebView())
        LoadWebViews()
        
    }
   
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == TabsIdentifier {
            let tabsViewController = segue.destination as! TabsTableViewController
            tabsViewController.tabs = self.tabs
            tabsViewController.delagate = self
            tabsViewController.selectedTab = selectedTab
            
        }else {
            let bookmarksViewController = segue.destination as! BookMarksTableViewController
            bookmarksViewController.bookmarks = self.bookmarks
            bookmarksViewController.delagate = self
        }
    }
}
