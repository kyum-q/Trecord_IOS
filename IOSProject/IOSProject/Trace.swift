import Foundation
import Firebase

class Trace: NSObject {
    var owner: String = "kyung Mi"
    var key: String
    
    var date: Date
    var location: [String: Double?] = ["lon": nil, "lat": nil]
    var locationTitle: String
    var locationAddress: String
    var colorIndex : Int
    var image: UIImage?
    var imageUrl: String?
    var content: String?
    
    init(date: Date, location: [String: Double?], locationTitle: String, locationAddress: String) {
        self.key = UUID().uuidString
        self.date = Date(timeInterval: 0, since: date)
        self.location = location
        self.locationTitle = locationTitle
        self.locationAddress = locationAddress
        self.colorIndex = 1
        
        super.init()
    }
    
    override init(){
        self.key = UUID().uuidString
        self.date = Date()
        self.location = ["lon": nil, "lat": nil]
        self.locationTitle = ""
        self.locationAddress = ""
        self.colorIndex = 1
        
        super.init()
    }
}

extension Trace {
    func toDict() -> [String: Any?] {
        var dict: [String: Any?] = [:]
        
        dict["date"] = Timestamp(date: date)
        dict["location"] = location
        dict["locationTitle"] = locationTitle
        dict["locationAddress"] = locationAddress
        dict["imageUrl"] = imageUrl
        dict["content"] = content
        dict["colorIndex"] = colorIndex
        
        return dict
    }
    
    func toTrace(dict: [String: Any?]) {
        
        key = dict["key"] as? String ?? ""
        date = Date()
        
        if let timestamp = dict["date"] as? Timestamp {
            date = timestamp.dateValue()
        }
        location = dict["location"] as! [String: Double?]
        locationTitle = dict["locationTitle"] as! String
        locationAddress = dict["locationAddress"] as! String
        imageUrl = dict["imageUrl"] as? String
        content = dict["content"] as? String
        colorIndex = dict["colorIndex"] as! Int
        
        if let imageUrl = imageUrl {
            DispatchQueue.global().async {
                self.image = self.getImage()
            }
        }
        else {
            image = nil
        }
    }
    
    func getImage() -> UIImage? {
        if let imageUrl = imageUrl {
            if let url = URL(string: imageUrl), let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                self.image = image
                return image
            }
        }
        return nil
    }
}
