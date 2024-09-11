//
//  UIDevice+Extensions.swift
//  BudChat
//
//  Created by lai A on 2023/8/22.
//  Copyright © 2023 BudChat LLC. All rights reserved.
//

import AdSupport
import Foundation
import SwiftKeychainWrapper
import UIKit

extension UIDevice {
    public static func deviceUUID() -> String {
        let keyDeviceID = "key_device_uuid"
        var resultString: String? = KeychainWrapper.standard.string(forKey: keyDeviceID)

        if resultString == nil {
            let uuidRef: CFUUID = CFUUIDCreate(kCFAllocatorDefault)
            let strUUID: String = CFUUIDCreateString(kCFAllocatorDefault, uuidRef) as String

            if strUUID.count > 0 {
                KeychainWrapper.standard.set(strUUID, forKey: keyDeviceID)
                resultString = strUUID
            }
        }

        return resultString ?? ""
    }

//    / A textual representation of the device.(e.g. iPhone X or iPhone 8).
    static func deviceName() -> String {
        return UIDevice.current.description
    }

    /// The current version of the operating system (e.g. 8.4 or 9.2).
    static func deviceSystemVersion() -> String {
        let name = UIDevice.current.systemVersion

        return name
    }

    /// The name of the operating system running on the device represented by the receiver (e.g. "iOS" or "tvOS").
    static func deviceSystemName() -> String {
        let name = UIDevice.current.systemName

        return name
    }
}

extension UIDevice {
    var ipAddress: String {
        var addresses = [String]()
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let flags = Int32(ptr!.pointee.ifa_flags)
                var addr = ptr!.pointee.ifa_addr.pointee
                if (flags & (IFF_UP | IFF_RUNNING | IFF_LOOPBACK)) == (IFF_UP | IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                            if let address = String(validatingUTF8: hostname) {
                                addresses.append(address)
                            }
                        }
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return addresses.first ?? "0.0.0.0"
    }

    /// 获取公网 ip, http://ip.taobao.com/service/getIpInfo.php?ip=myip
    /**
     {
         "code": 0,
         "data": {
             "ip": "221.6.47.187",
             "country": "中国",
             "area": "",
             "region": "江苏",
             "city": "南京",
             "county": "XX",
             "isp": "联通",
             "country_id": "CN",
             "area_id": "",
             "region_id": "320000",
             "city_id": "320100",
             "county_id": "xx",
             "isp_id": "100026"
         }
     }
     */
    var publicIp: String? {
        guard let ipUrl = URL(string: "http://ip.taobao.com/service/getIpInfo.php?ip=myip") else {
            return nil
        }

        guard let data = try? Data(contentsOf: ipUrl) else {
            return nil
        }

        guard let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
            return nil
        }

        guard let dataDict = dict["data"] as? [String: Any] else {
            return nil
        }

        return dataDict["ip"] as? String
    }

    /// IDFA 广告标识
    static let deviceIDFA: String = {
        if #available(iOS 10.0, *) {
            guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
                return ""
            }
        }
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }()

    static var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        switch identifier {
        // TODO: iPod touch
        case "iPod1,1": return "iPod touch"
        case "iPod2,1": return "iPod touch (2nd generation)"
        case "iPod3,1": return "iPod touch (3rd generation)"
        case "iPod4,1": return "iPod touch (4th generation)"
        case "iPod5,1": return "iPod touch (5th generation)"
        case "iPod7,1": return "iPod touch (6th generation)"
        case "iPod9,1": return "iPod touch (7th generation)"
        // TODO: iPad
        case "iPad1,1": return "iPad"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3": return "iPad (3rd generation)"
        case "iPad3,4", "iPad3,5", "iPad3,6": return "iPad (4th generation)"
        case "iPad6,11", "iPad6,12": return "iPad (5th generation)"
        case "iPad7,5", "iPad7,6": return "iPad (6th generation)"
        case "iPad7,11", "iPad7,12": return "iPad (7th generation)"
        case "iPad11,6", "iPad11,7": return "iPad (8th generation)"
        case "iPad12,1", "iPad12,2": return "iPad (9th generation)"
        // TODO: iPad Air
        case "iPad4,1", "iPad4,2", "iPad4,3": return "iPad Air"
        case "iPad5,3", "iPad5,4": return "iPad Air 2"
        case "iPad11,3", "iPad11,4": return "iPad Air (3rd generation)"
        case "iPad13,1", "iPad13,2": return "iPad Air (4rd generation)"
        // TODO: iPad Pro
        case "iPad6,3", "iPad6,4": return "iPad Pro (9.7-inch)"
        case "iPad7,3", "iPad7,4": return "iPad Pro (10.5-inch)"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4": return "iPad Pro (11-inch)"
        case "iPad8,9", "iPad8,10": return "iPad Pro (11-inch) (2nd generation)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro (11-inch) (3rd generation)"
        case "iPad6,7", "iPad6,8": return "iPad Pro (12.9-inch)"
        case "iPad7,1", "iPad7,2": return "iPad Pro (12.9-inch) (2nd generation)"
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8": return "iPad Pro (12.9-inch) (3rd generation)"
        case "iPad8,11", "iPad8,12": return "iPad Pro (12.9-inch) (4th generation)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro (12.9-inch) (5th generation)"
        // TODO: iPad mini
        case "iPad2,5", "iPad2,6", "iPad2,7": return "iPad mini"
        case "iPad4,4", "iPad4,5", "iPad4,6": return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9": return "iPad Mini 3"
        case "iPad5,1", "iPad5,2": return "iPad Mini 4"
        case "iPad11,1", "iPad11,2": return "iPad mini (5th generation)"
        case "iPad14,1", "iPad14,2": return "iPad mini (6th generation)"
        // TODO: iPhone
        case "iPhone1,1": return "iPhone"
        case "iPhone1,2": return "iPhone 3G"
        case "iPhone2,1": return "iPhone 3GS"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3": return "iPhone 4"
        case "iPhone4,1": return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2": return "iPhone 5"
        case "iPhone5,3", "iPhone5,4": return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2": return "iPhone 5s"
        case "iPhone7,2": return "iPhone 6"
        case "iPhone7,1": return "iPhone 6 Plus"
        case "iPhone8,1": return "iPhone 6s"
        case "iPhone8,2": return "iPhone 6s Plus"
        case "iPhone8,4": return "iPhone SE (1st generation)"
        case "iPhone9,1", "iPhone9,3": return "iPhone 7"
        case "iPhone9,2", "iPhone9,4": return "iPhone 7 Plus"
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone12,8": return "iPhone SE (2nd generation)"
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,6": return "iPhone SE (3rd generation)"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "AppleTV5,3": return "Apple TV"
        case "i386", "x86_64": return "iPhone Simulator"
        default: return identifier
        }
    }
}
