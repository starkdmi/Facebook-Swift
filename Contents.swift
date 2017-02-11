
import PlaygroundSupport
import UIKit
import WebKit
import Foundation

extension String {
    func indexOf(target: String) -> Int {
        var range = self.range(of: target)
        if let range = range {
            return distance(from: self.startIndex, to: range.lowerBound)
        } 
        else
        {
            return -1
        }
    }
}

extension String.Index{
    func advance(_ offset:Int, for string:String)->String.Index{
        return string.index(self, offsetBy: offset)
    }
}

extension UIImage {
    var circle: UIImage? {
        let square = CGSize(width: min(size.width, size.height), height: min(size.width, size.height))
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: square))
        imageView.contentMode = .scaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}

extension UIColor { 
    class func hex (hexStr : String, alpha : CGFloat) -> UIColor { 
        var hexStr = hexStr
        hexStr = hexStr.replacingOccurrences(of: "#", with: "") 
        let scanner = Scanner(string: hexStr) 
        var color: UInt32 = 0 
        if scanner.scanHexInt32(&color) { 
            let r = CGFloat((color & 0xFF0000) >> 16) / 255.0 
            let g = CGFloat((color & 0x00FF00) >> 8) / 255.0 
            let b = CGFloat(color & 0x0000FF) / 255.0 
            return UIColor(red:r,green:g,blue:b,alpha:alpha) 
        } else { 
            return UIColor.white; 
        } 
    } 
}

var Facebook_Access_Token: String? = nil
var Facebook_Client_Id: String = "1643305975908757"
typealias Facebook_Dictionary = Dictionary<String,Any>

func GetReguest(_ str:String) -> String {
    let url = URL(string: str)
    do {
            let contents = try NSString(contentsOf: url!, usedEncoding: nil)
            return contents as String
    } catch {
        // Ошибка
        return NSError.description()
    }
}

func ParseJsonData(_ str: String) -> Facebook_Dictionary
{
    var data = str.data(using: .utf8)!
    
    let jsonObject = try? JSONSerialization.jsonObject(with: data) as! [String:Any]
    
    var response: Facebook_Dictionary? = ["name":"Имя"]
    
    response?["name"] = jsonObject?["name"] as! String
    
    let photo_picture = jsonObject?["picture"] as! [String:Any]
    let photo_data = photo_picture["data"] as! [String:Any]
    var photo_url: String = photo_data["url"] as! String
    //response?["photo"] = photo_url
    
    //var array_strings = (photo_url as! String).components(separatedBy: "/")
    
    //array_strings[6] = "s50x50"
    //var new_photo_url: String = ""
    
    /*for i in 0 ... array_strings.count - 1 {
        if i < array_strings.count - 1 {
            new_photo_url += array_strings[i] + "/"
        }
        else
        {
            new_photo_url += array_strings[i]
        }
    }*/
    
    /*let photo_id = array_strings[7].components(separatedBy: "?")[0]*/
    
    /*new_photo_url = "https://scontent-a.xx.fbcdn.net/hphotos-xpf1/t31.0-8/" + photo_id*/
    
    response?["photo"] = photo_url
    
    return response!
}

class AuthController: UIViewController, UIWebViewDelegate, WKUIDelegate, WKNavigationDelegate{  
    @IBOutlet var containerView : UIView? = nil  
    var webView: WKWebView?  
    
    override func loadView(){  
        super.loadView()  
        webView = WKWebView()  
        self.view = webView
    }  
    
    override func viewDidLoad(){  
        super.viewDidLoad()  
        
         UserDefaults.standard.removeObject(forKey: "Facebook_Access_Token")
        
        if let token = UserDefaults.standard.string(forKey: "Facebook_Access_Token")
        {
            webView?.isHidden = true
            
            Facebook_Access_Token = token
            
            let mainPage = MainController()
            PlaygroundPage.current.liveView = UINavigationController(rootViewController: mainPage)
            PlaygroundPage.current.needsIndefiniteExecution = true
        }
        else
        {
            var url = URL(string:"https://www.facebook.com/dialog/oauth?client_id=\(Facebook_Client_Id)&redirect_uri=https://www.facebook.com/connect/login_success.html&response_type=token&scope=public_profile&display=popup")  
            
            url?.removeAllCachedResourceValues()
            
        var req = URLRequest(url:url!)  
            webView!.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
            webView!.load(req) 
        }
    }  
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            if webView?.estimatedProgress == 1.0
            {
                if ((webView?.url?.absoluteURL.absoluteString.range(of: "access_token")) != nil) && webView?.url?.host == "www.facebook.com" {
                    let host = webView?.url?.host
                    webView?.isHidden = true
                    
                    let parameters = webView?.url?.absoluteURL.absoluteString.components(separatedBy: "#")[1]
                    
                    let parameters_token = parameters?.components(separatedBy: "&")[0]
                    
                    Facebook_Access_Token = parameters?.substring(with: (parameters_token?.characters.startIndex.advance(13, for: parameters_token!))!..<(parameters_token?.characters.endIndex)!)
                    
                    UserDefaults.standard.set(Facebook_Access_Token, forKey: "Facebook_Access_Token")
                    
                    webView?.removeObserver(self, forKeyPath: "estimatedProgress")
                    
                    let mainPage = MainController()
                    PlaygroundPage.current.liveView = UINavigationController(rootViewController: mainPage)
                    PlaygroundPage.current.needsIndefiniteExecution = true
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

class MainController: UIViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Facebook"
        
        let content = GetReguest("https://graph.facebook.com/v2.3/me?fields=name,picture,link&access_token=" + Facebook_Access_Token!)
        
        let info = ParseJsonData(content)
        
        view.sizeToFit()
        view.backgroundColor = UIColor.hex(hexStr: "#3B5998", alpha: 1.0)
        
        // let height = view.frame.size.height
        // let width = view.frame.size.width
        
        let imageView = UIImageView(frame: CGRect(x: 30, y: 70, width: 100, height: 100))
        
        let profileImage = UIImage(data: try! Data(contentsOf: URL(string: info["photo"] as! String)!))!
        
        imageView.image = profileImage.circle
        
        let nameLabel = UILabel(frame: CGRect(x: 140, y: 80, width: 200, height: 100))
        nameLabel.text = (info["name"] as! String)
        nameLabel.textColor = #colorLiteral(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        nameLabel.sizeToFit()
        
        /*let cityLabel = UILabel(frame: CGRect(x: 140, y: 110, width: 200, height: 100))
        cityLabel.text = (info["city"] as! String)
        cityLabel.textColor = #colorLiteral(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        cityLabel.sizeToFit()*/
        
        view.addSubview(imageView)
        view.addSubview(nameLabel)
        //view.addSubview(cityLabel)
    }
}

let AuthPage = AuthController()
PlaygroundPage.current.liveView = AuthPage
PlaygroundPage.current.needsIndefiniteExecution = true
