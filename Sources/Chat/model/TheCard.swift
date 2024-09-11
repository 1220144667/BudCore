//
//  TheCard.swift
//
//  Copyright © 2019-2022 BudChat LLC. All rights reserved.
//

import Foundation
import UIKit

public class Photo: Codable {
    public static let kDefaultType = "png"

    // The specific part of the image mime type, e.g. if mime type is "image/png", the type is "png".
    public let type: String?
    // Image bits.
    public let data: Data?
    // URL of the image for out-of-band avatars
    public let ref: String?
    // Width and height of the image.
    public let width: Int?
    public let height: Int?
    // Cached decoded image (not serialized).
    private var cachedImage: UIImage?

    private enum CodingKeys: String, CodingKey {
        case type, data, ref, width, height
    }

    public init(type tp: String = Photo.kDefaultType, data: Data?, ref: String?, width: Int? = nil, height: Int? = nil) {
        // Extract specific part from the full mime type.
        let parts = tp.components(separatedBy: "/")
        if parts.count > 1 {
            if parts[0] == "image" {
                // Drop the first component "image/", keep the rest.
                type = parts[1 ..< parts.count].joined(separator: "/")
            } else {
                // Invalid mime type, use default value.
                type = Photo.kDefaultType
            }
        } else {
            type = tp
        }

        self.data = data
        self.ref = ref
        self.width = width
        self.height = height
    }

    public convenience init(type: String = Photo.kDefaultType, ref: String?) {
        self.init(type: type, data: nil, ref: ref, width: nil, height: nil)
    }

    public convenience init(image: UIImage) {
        self.init(type: Photo.kDefaultType, data: image.pngData(), ref: nil, width: Int(image.size.width), height: Int(image.size.height))
        cachedImage = image
    }

    public var image: UIImage? {
        if cachedImage == nil {
            guard let data = data else { return nil }
            cachedImage = UIImage(data: data)
        }
        return cachedImage
    }

    public func copy() -> Photo {
        let copy = Photo(type: type ?? Photo.kDefaultType, data: data, ref: ref, width: width, height: height)
        copy.cachedImage = cachedImage
        return copy
    }
}

public class Organization: Codable {
    var fn: String?
    var title: String?
    init() {}
    public func copy() -> Organization {
        let copy = Organization()
        copy.fn = fn
        copy.title = title
        return copy
    }
}

public class Contact: Codable {
    var type: String?
    public var uri: String?
    init() {}
    public func copy() -> Contact {
        let contactCopy = Contact()
        contactCopy.type = type
        contactCopy.uri = uri
        return contactCopy
    }
}

public class Name: Codable {
    var surname: String?
    var given: String?
    var additional: String?
    var prefix: String?
    var suffix: String?
    init() {}
    public func copy() -> Name {
        let nameCopy = Name()
        nameCopy.surname = surname
        nameCopy.given = given
        nameCopy.additional = additional
        nameCopy.prefix = prefix
        nameCopy.suffix = suffix
        return nameCopy
    }
}

public class Birthday: Codable {
    // Year like 1975
    var y: Int16?
    // Month 1..12.
    var m: Int8?
    // Day 1..31.
    var d: Int8?
    init() {}
    public func copy() -> Birthday {
        let copy = Birthday()
        copy.y = y
        copy.m = m
        copy.d = d
        return copy
    }
}

public class TheCard: Codable, Mergeable {
    public var fn: String?
    public var n: Name?
    public var org: Organization?
    // List of phone numbers associated with the contact.
    public var tel: [Contact]?
    // List of contact's email addresses.
    public var email: [Contact]?
    public var impp: [Contact]?
    // Avatar photo.
    public var photo: Photo?
    public var bday: Birthday?
    // Free-form description.
    public var note: String?

    public var gender: String?
    public var mail: String?

    public var rn: String?

    private enum CodingKeys: String, CodingKey {
        case fn, n, org, tel, email, impp, photo, bday, note, gender, mail, rn
    }

    public init() {}

    public init(fn: String?,
                realName: String? = nil,
                avatar: Photo?,
                note: String? = nil)
    {
        self.fn = fn
        rn = realName

        photo = avatar
        self.note = note
    }

    public init(fn: String?) {
        self.fn = fn
    }

    public init(fn: String?,
                realName: String? = nil,
                avatar: UIImage? = nil,
                note: String? = nil)
    {
        self.fn = fn
        rn = realName
        self.note = note

        guard let avatar = avatar else { return }
        photo = Photo(image: avatar)
    }

    public func copy() -> TheCard {
        let copy = TheCard(fn: fn, realName: rn, avatar: photo?.copy())
        copy.n = n
        copy.org = org?.copy()
        copy.tel = tel?.map { $0 }
        copy.email = email?.map { $0 }
        copy.impp = impp?.map { $0 }
        copy.bday = bday?.copy()
        copy.note = note
        return copy
    }

    public var photoRefs: [String]? {
        guard let ref = photo?.ref else { return nil }
        return [ref]
    }

    public var photoBits: Data? {
        return photo?.data
    }

    public var photoMimeType: String {
        return "image/\(photo?.type ?? Photo.kDefaultType)"
    }

    public func merge(with another: Mergeable) -> Bool {
        guard let another = another as? TheCard else { return false }
        var changed = false
        if another.fn != nil {
            fn = !BudChat.isNull(obj: another.fn) ? another.fn : nil
            changed = true
        }
        if another.org != nil {
            org = !BudChat.isNull(obj: another.org) ? another.org : nil
            changed = true
        }
        if another.tel != nil {
            tel = !BudChat.isNull(obj: another.tel) ? another.tel : nil
            changed = true
        }
        if another.email != nil {
            email = !BudChat.isNull(obj: another.email) ? another.email : nil
            changed = true
        }
        if another.impp != nil {
            impp = !BudChat.isNull(obj: another.impp) ? another.impp : nil
            changed = true
        }
        if another.photo != nil {
            photo = !BudChat.isNull(obj: another.photo) ? another.photo!.copy() : nil
            changed = true
        }
        if another.bday != nil {
            bday = !BudChat.isNull(obj: another.bday) ? another.bday!.copy() : nil
            changed = true
        }
        if another.note != nil {
            note = !BudChat.isNull(obj: another.note) ? another.note : nil
            changed = true
        }
        return changed
    }
}
