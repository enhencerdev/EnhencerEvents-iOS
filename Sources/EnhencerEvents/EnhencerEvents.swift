import Foundation
import FacebookCore
import FBSDKCoreKit
import FirebaseAnalytics


public struct EnhencerEvents {
    
    var userID: String;
    var visitorID: String;
    var type = "ecommerce";
    var advertiserTrackingEnabled = false
    var appTrackingEnabled = false
    //var listingUrl = "https://collect.enhencer.com/api/listings/";
    //var productUrl = "https://collect.enhencer.com/api/products/";
    //var purchaseUrl = "https://collect.enhencer.com/api/purchases/";
    //var customerUrl = "https://collect.enhencer.com/api/customers/";
    var listingUrl = "http://localhost:4000/api/listings/";
    var productUrl = "http://localhost:4000/api/products/";
    var purchaseUrl = "http://localhost:4000/api/purchases/";
    var customerUrl = "http://localhost:4000/api/customers/";
    
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
    
    public mutating func config (token: String, advertiserTrackingEnabled: Bool = false, applicationTrackingEnabled: Bool = false ){
        self.userID = token
    }
    
    private func generateVisitorID() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map{ _ in letters.randomElement()! })
    }
    
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
            "deviceType": "iOS",
            "userID": self.userID,
            "id": self.visitorID,
            "eventSourceUrl": "dummy_source",
            "fbp": "fbp replacement",
            "userAgent": "user agent"
        ]
        let _ = sendRequest(toUrl: self.customerUrl + self.visitorID, withParameters: parameters, requestMethod: "PUT", completion: self.pushResult(apiResponse:))
    }
    
    private func pushResult(apiResponse: [String: Any]) {
        
        for aud in apiResponse["audiences"] as! [[String:String]] {
            let params = [
                AppEvents.ParameterName(rawValue: "eventID"): aud["eventId"]!
            ]
            
            // push to facebook
            AppEvents.shared.logEvent(AppEvents.Name(aud["name"]!), parameters: params)
            
            // push to firebase
            Analytics.logEvent(aud["name"]!, parameters: [:])
        }
    }
    
    
    
    private func sendRequest (toUrl: String, withParameters: [String: Any], requestMethod: String? = "POST", completion: (([String: Any]) -> ())? = { _ in return }) -> Bool {
        var request = URLRequest(url: URL(string: toUrl)!)
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.setValue("text/plain", forHTTPHeaderField: "Accept")
        request.httpMethod = requestMethod
        
        do {
            let body = try JSONSerialization.data(withJSONObject: withParameters)
            request.httpBody = Data(String(decoding: body, as: UTF8.self).utf8)
            
        } catch {
            print("error ", error)
        }
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                error == nil
            else {                                                               // check for fundamental networking error
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            
            guard (200 ... 300) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
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
