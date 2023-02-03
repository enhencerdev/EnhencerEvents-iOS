import Foundation
import AppTrackingTransparency

#if canImport(FacebookCore)
import FacebookCore
#endif

#if canImport(FacebookCoreKit)
import FBSDKCoreKit
#endif

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif



public struct EnhencerEvents {
    
    var userID: String;
    var visitorID: String;
    var type = "ecommerce";
    var advertiserTrackingEnabled = 1
    var appTrackingEnabled = true
    var fbExternalID = "";
    var listingUrl = "https://collect-app.enhencer.com/api/listings/";
    var productUrl = "https://collect-app.enhencer.com/api/products/";
    var purchaseUrl = "https://collect-app.enhencer.com/api/purchases/";
    var customerUrl = "https://collect-app.enhencer.com/api/customers/";
    
    public static var shared = EnhencerEvents()
    
    private init() {
        
        self.userID = "";
        self.visitorID = "";
        if let v = UserDefaults.standard.string(forKey: "enh_visitor_session") {
            self.visitorID = v;
        } else {
            let v = self.generateVisitorID();
            self.visitorID = v;
            UserDefaults.standard.set(v, forKey: "enh_visitor_session")
        }
        
    }
    
    /// Configures and initializes the EnhencerEvents struct.
    ///
    /// - Parameters:
    ///     - token: Your Enhencer user ID provided to you.
    public mutating func config (token: String ){
        self.userID = token
        setTrackingStatus()
        print(AppEvents.shared)
    }
    
    
    private mutating func setTrackingStatus (){
        if #available(iOS 14.0, *) {
            self.advertiserTrackingEnabled = (ATTrackingManager.trackingAuthorizationStatus == .denied) ? 0 : 1
        }
        
        do {
            
            if (AppEvents.shared.getUserData() != nil) {
                let userData = try JSONSerialization.jsonObject(with: AppEvents.shared.getUserData()?.data(using: .utf8)! ?? "{}".data(using: .utf8)! , options: []) as! [String: Any]
                self.fbExternalID = userData["external_id"] as? String ?? self.visitorID
                if let id = userData["external_id"] as? String {
                    self.fbExternalID = id
                } else {
                    self.fbExternalID = self.visitorID
                    AppEvents.shared.setUserData(self.visitorID, forType: FBSDKAppEventUserDataType(rawValue: "external_id"))
                }
            } else {
                self.fbExternalID = self.visitorID
                AppEvents.shared.setUserData(self.visitorID, forType: FBSDKAppEventUserDataType(rawValue: "external_id"))
            }
            
        } catch {
            self.fbExternalID = self.visitorID
            AppEvents.shared.setUserData(self.visitorID, forType: FBSDKAppEventUserDataType(rawValue: "external_id"))
        }
    }
    
    private func generateVisitorID() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map{ _ in letters.randomElement()! })
    }
    
    /// Sends the product listing page view event to Enhencer.
    ///
    /// - Parameters:
    ///     - category: The category of the page viewed, ex. 'ANC Headphones'.
    public func listingPageView(category: String) {
        let parameters: [String: Any] = [
            "type": self.type,
            "visitorID": self.visitorID,
            "productCategory1": category,
            "productCategory2": "",
            "deviceType": "iOS",
            "userID": self.userID,
            "id": self.visitorID
        ]
        
        let _ = sendRequest(toUrl: self.listingUrl, withParameters: parameters)
        let _ = sendRequest(toUrl: self.customerUrl, withParameters: parameters)
        self.scoreMe()
        
    }
    
    /// Sends the product detail page view event to Enhencer.
    ///
    /// - Parameters:
    ///     - productID: The ID of the product that is being viewed.
    ///     - productCategory: The category of the product that is being viewed.
    ///     - productPrice: The price of the product that is being viewed.
    public func productPageView(productID: String, productCategory: String, productPrice: Int) {
        let parameters: [String: Any] = [
            "type": self.type,
            "visitorID": self.visitorID,
            "productID": productID,
            "productCategory2": productCategory,
            "price": productPrice,
            "deviceType": "iOS",
            "actionType": "product",
            "userID": self.userID,
            "id": self.visitorID
        ]
        
        let _ = sendRequest(toUrl: self.productUrl, withParameters: parameters)
        let _ = sendRequest(toUrl: self.customerUrl, withParameters: parameters)
        self.scoreMe()
        
    }
    
    /// Sends the add to cart event to Enhencer.
    ///
    /// - Parameters:
    ///     - productID: The ID of the product that is being added to the cart.
    public func addedToCart(productID: String) {
        let parameters: [String: Any] = [
            "type": self.type,
            "visitorID": self.visitorID,
            "productID": productID,
            "deviceType": "iOS",
            "actionType": "basket",
            "userID": self.userID,
            "id": self.visitorID
        ]
        
        let _ = sendRequest(toUrl: self.purchaseUrl, withParameters: parameters)
        let _ = sendRequest(toUrl: self.customerUrl, withParameters: parameters)
        self.scoreMe()
        
    }
    
    /// Sends the add to cart event to Enhencer.
    ///
    /// - Parameters:
    ///     - products: An array containing the purchased product dictionaries. Dictionaries has to include 'id', 'quantity' and 'price' fields.
    ///     Ex: [ 'id': 'product_id', 'quantity': 1, 'price': 15 ]
    public func purchased(products: [[String: Any]] = [[ "id": "no-id", "quantity": 1, "price": 1 ]]) {
        
        let basketID = String(Date().toMilliseconds())
        
        let parameters: [String: Any] = [
            "type": self.type,
            "visitorID": self.visitorID,
            "products": products,
            "basketID": basketID,
            "actionType": "purchase",
            "deviceType": "iOS",
            "userID": self.userID,
            "id": self.visitorID
        ]
        
        let _ = sendRequest(toUrl: self.purchaseUrl, withParameters: parameters)
        let _ = sendRequest(toUrl: self.customerUrl, withParameters: parameters)
        self.scoreMe()
        
    }
    
    
    private func scoreMe() {
        let parameters: [String: Any] = [
            "type": self.type,
            "visitorID": self.visitorID,
            "userID": self.userID,
            "id": self.visitorID,
            "deviceOsVersion": UIDevice.current.systemVersion,
            "deviceType": "i2",
            "advertiserTrackingEnabled": self.advertiserTrackingEnabled,
            "externalID": self.fbExternalID
        ]
        let _ = sendRequest(toUrl: self.customerUrl + self.visitorID, withParameters: parameters, requestMethod: "PUT", completion: self.pushResult(apiResponse:))
    }
    
    private func pushResult(apiResponse: [String: Any]) {
        
        for aud in apiResponse["audiences"] as! [[String:String]] {
            self.pushToFacebook(audience: aud)
            self.pushToGoogle(audience: aud)
        }
    }
    
    private func pushToFacebook (audience: [String:String]){
        
        let params = [
            AppEvents.ParameterName(rawValue: "eventID"): audience["eventId"]!,
        ]
        
        AppEvents.shared.logEvent(AppEvents.Name(audience["name"]!), parameters: params)
    }
    
    private func pushToGoogle (audience: [String:String]){
        // push to firebase
        var name = audience["name"]!
        name = name.replacingOccurrences(of: " ", with: "_")
        name = name.lowercased()
        Analytics.logEvent(name, parameters: [:])
    }
    
    
    
    private func sendRequest (toUrl: String, withParameters: [String: Any], requestMethod: String? = "POST", completion: (([String: Any]) -> ())? = { _ in return }) -> Bool {
        var request = URLRequest(url: URL(string: toUrl)!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = requestMethod
        
        do {
            let body = try JSONSerialization.data(withJSONObject: withParameters)
            request.httpBody = Data(body)
            
        } catch {
            print("error ", error)
        }
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                error == nil
            else {                                                               // check for fundamental networking error
                //print("error", error ?? URLError(.badServerResponse))
                return
            }
            
            guard (200 ... 300) ~= response.statusCode else {                    // check for http errors
                //print("statusCode should be 2xx, but is \(response.statusCode)")
                //print("response = \(response)")
                return
            }
            do {
                let r = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                completion!(r ?? [:])
                
            } catch {
                print("error ", error)
            }
            
        }
        
        task.resume()
        
        return true
    }
    
    
    
}


extension Dictionary {
    func percentEncoded() -> Data? {
        map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed: CharacterSet = .urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

struct ResponseObject<T: Decodable>: Decodable {
    let form: T    // often the top level key is `data`, but in the case of https://httpbin.org, it echos the submission under the key `form`
}

struct Response: Decodable {
    let content: String
}

extension Date {
    func toMilliseconds() -> Int64! {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}
