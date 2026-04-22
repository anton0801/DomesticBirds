import Foundation
import SwiftUI

struct AppUser: Codable {
    var id: String
    var name: String
    var email: String
    var farmName: String
    var createdAt: Date

    init(id: String = UUID().uuidString, name: String, email: String, farmName: String = "") {
        self.id = id
        self.name = name
        self.email = email
        self.farmName = farmName
        self.createdAt = Date()
    }
}

// MARK: - Bird Catalog
enum BirdCategory: String, CaseIterable, Codable {
    case chickens = "Chickens"
    case ducks = "Ducks"
    case geese = "Geese"
    case turkeys = "Turkeys"
    case quails = "Quails"
    case guineaFowl = "Guinea Fowl"
    case pheasants = "Pheasants"

    var icon: String {
        switch self {
        case .chickens: return "🐔"
        case .ducks: return "🦆"
        case .geese: return "🪿"
        case .turkeys: return "🦃"
        case .quails: return "🐦"
        case .guineaFowl: return "🐓"
        case .pheasants: return "🦚"
        }
    }

    var color: Color {
        switch self {
        case .chickens: return Color(hex: "#E8A020")
        case .ducks: return Color(hex: "#3A9BD5")
        case .geese: return Color(hex: "#7B5EA7")
        case .turkeys: return Color(hex: "#C1440E")
        case .quails: return Color(hex: "#52A865")
        case .guineaFowl: return Color(hex: "#8B6914")
        case .pheasants: return Color(hex: "#D4A843")
        }
    }
}

struct BirdBreed: Identifiable, Codable {
    let id: String
    let name: String
    let category: BirdCategory
    let origin: String
    let description: String
    let weightMale: Double   // kg
    let weightFemale: Double // kg
    let eggsPerYear: Int
    let eggColor: String
    let temperament: String
    let purpose: String
    let lifespan: String
    let maturityWeeks: Int
    let colorPattern: String

    init(id: String = UUID().uuidString, name: String, category: BirdCategory,
         origin: String, description: String, weightMale: Double, weightFemale: Double,
         eggsPerYear: Int, eggColor: String, temperament: String, purpose: String,
         lifespan: String, maturityWeeks: Int, colorPattern: String) {
        self.id = id
        self.name = name
        self.category = category
        self.origin = origin
        self.description = description
        self.weightMale = weightMale
        self.weightFemale = weightFemale
        self.eggsPerYear = eggsPerYear
        self.eggColor = eggColor
        self.temperament = temperament
        self.purpose = purpose
        self.lifespan = lifespan
        self.maturityWeeks = maturityWeeks
        self.colorPattern = colorPattern
    }
}

enum BirdGender: String, CaseIterable, Codable {
    case female = "Female"
    case male = "Male"
    case unknown = "Unknown"
}

enum BirdHealthStatus: String, CaseIterable, Codable {
    case healthy = "Healthy"
    case sick = "Sick"
    case recovering = "Recovering"
    case quarantine = "Quarantine"

    var color: Color {
        switch self {
        case .healthy: return .dbGreen
        case .sick: return Color(hex: "#E53E3E")
        case .recovering: return Color(hex: "#E8A020")
        case .quarantine: return Color(hex: "#805AD5")
        }
    }
}

struct MyBird: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var type: BirdCategory
    var breed: String
    var gender: BirdGender
    var birthDate: Date
    var groupId: String?
    var coopId: String?
    var healthStatus: BirdHealthStatus
    var weight: Double
    var notes: String
    var tagNumber: String
    var acquisitionDate: Date
    var isActive: Bool

    var ageInMonths: Int {
        Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0
    }

    var ageDisplay: String {
        let months = ageInMonths
        if months < 1 { return "< 1 month" }
        if months < 12 { return "\(months) month\(months > 1 ? "s" : "")" }
        let years = months / 12
        let rem = months % 12
        if rem == 0 { return "\(years) year\(years > 1 ? "s" : "")" }
        return "\(years)y \(rem)m"
    }

    init(id: String = UUID().uuidString, name: String, type: BirdCategory, breed: String,
         gender: BirdGender = .unknown, birthDate: Date = Date(), groupId: String? = nil,
         coopId: String? = nil, healthStatus: BirdHealthStatus = .healthy, weight: Double = 0,
         notes: String = "", tagNumber: String = "", acquisitionDate: Date = Date(), isActive: Bool = true) {
        self.id = id
        self.name = name
        self.type = type
        self.breed = breed
        self.gender = gender
        self.birthDate = birthDate
        self.groupId = groupId
        self.coopId = coopId
        self.healthStatus = healthStatus
        self.weight = weight
        self.notes = notes
        self.tagNumber = tagNumber
        self.acquisitionDate = acquisitionDate
        self.isActive = isActive
    }
}

// MARK: - Groups
enum GroupPurpose: String, CaseIterable, Codable {
    case layers = "Layers"
    case youngBirds = "Young Birds"
    case breeding = "Breeding"
    case meat = "Meat"
    case mixed = "Mixed"

    var color: Color {
        switch self {
        case .layers: return Color(hex: "#52A865")
        case .youngBirds: return Color(hex: "#3A9BD5")
        case .breeding: return Color(hex: "#E8A020")
        case .meat: return Color(hex: "#C1440E")
        case .mixed: return Color(hex: "#805AD5")
        }
    }
}

struct BirdGroup: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var purpose: GroupPurpose
    var birdCount: Int
    var coopId: String?
    var notes: String
    var createdAt: Date

    init(id: String = UUID().uuidString, name: String, purpose: GroupPurpose = .mixed,
         birdCount: Int = 0, coopId: String? = nil, notes: String = "") {
        self.id = id
        self.name = name
        self.purpose = purpose
        self.birdCount = birdCount
        self.coopId = coopId
        self.notes = notes
        self.createdAt = Date()
    }
}

// MARK: - Egg Production
struct EggRecord: Identifiable, Codable, Hashable {
    var id: String
    var groupId: String
    var groupName: String
    var count: Int
    var date: Date
    var brokenCount: Int
    var notes: String

    init(id: String = UUID().uuidString, groupId: String, groupName: String,
         count: Int, date: Date = Date(), brokenCount: Int = 0, notes: String = "") {
        self.id = id
        self.groupId = groupId
        self.groupName = groupName
        self.count = count
        self.date = date
        self.brokenCount = brokenCount
        self.notes = notes
    }
}

// MARK: - Breeding
struct BreedingPair: Identifiable, Codable, Hashable {
    var id: String
    var maleBirdId: String
    var maleBirdName: String
    var femaleBirdId: String
    var femaleBirdName: String
    var startDate: Date
    var expectedHatchDate: Date?
    var eggsSet: Int
    var eggsHatched: Int
    var status: BreedingStatus
    var notes: String

    enum BreedingStatus: String, CaseIterable, Codable {
        case active = "Active"
        case incubating = "Incubating"
        case hatched = "Hatched"
        case completed = "Completed"
        case failed = "Failed"
    }

    init(id: String = UUID().uuidString, maleBirdId: String, maleBirdName: String,
         femaleBirdId: String, femaleBirdName: String, startDate: Date = Date(),
         expectedHatchDate: Date? = nil, eggsSet: Int = 0, eggsHatched: Int = 0,
         status: BreedingStatus = .active, notes: String = "") {
        self.id = id
        self.maleBirdId = maleBirdId
        self.maleBirdName = maleBirdName
        self.femaleBirdId = femaleBirdId
        self.femaleBirdName = femaleBirdName
        self.startDate = startDate
        self.expectedHatchDate = expectedHatchDate
        self.eggsSet = eggsSet
        self.eggsHatched = eggsHatched
        self.status = status
        self.notes = notes
    }
}

struct HatchRecord: Identifiable, Codable {
    var id: String
    var pairId: String
    var date: Date
    var chicksHatched: Int
    var chicksLost: Int
    var notes: String

    init(id: String = UUID().uuidString, pairId: String, date: Date = Date(),
         chicksHatched: Int = 0, chicksLost: Int = 0, notes: String = "") {
        self.id = id
        self.pairId = pairId
        self.date = date
        self.chicksHatched = chicksHatched
        self.chicksLost = chicksLost
        self.notes = notes
    }
}

// MARK: - Feeding
enum FeedType: String, CaseIterable, Codable {
    case layerPellets = "Layer Pellets"
    case starterFeed = "Starter Feed"
    case growerFeed = "Grower Feed"
    case corn = "Corn"
    case wheat = "Wheat"
    case scratch = "Scratch Mix"
    case supplement = "Supplement"
    case other = "Other"
}

struct FeedRecord: Identifiable, Codable {
    var id: String
    var groupId: String?
    var groupName: String
    var feedType: FeedType
    var amount: Double
    var unit: WeightUnit
    var date: Date
    var cost: Double
    var notes: String

    enum WeightUnit: String, CaseIterable, Codable {
        case kg = "kg"
        case lbs = "lbs"
        case g = "g"
    }

    init(id: String = UUID().uuidString, groupId: String? = nil, groupName: String = "All Birds",
         feedType: FeedType = .layerPellets, amount: Double = 0, unit: WeightUnit = .kg,
         date: Date = Date(), cost: Double = 0, notes: String = "") {
        self.id = id
        self.groupId = groupId
        self.groupName = groupName
        self.feedType = feedType
        self.amount = amount
        self.unit = unit
        self.date = date
        self.cost = cost
        self.notes = notes
    }
}

// MARK: - Health
enum HealthIssueType: String, CaseIterable, Codable {
    case respiratory = "Respiratory"
    case digestive = "Digestive"
    case parasites = "Parasites"
    case injury = "Injury"
    case vaccination = "Vaccination"
    case checkup = "Check-up"
    case other = "Other"
}

struct HealthRecord: Identifiable, Codable {
    var id: String
    var birdId: String?
    var birdName: String
    var issueType: HealthIssueType
    var description: String
    var treatment: String
    var date: Date
    var resolvedDate: Date?
    var isResolved: Bool
    var cost: Double
    var vetName: String

    init(id: String = UUID().uuidString, birdId: String? = nil, birdName: String,
         issueType: HealthIssueType = .checkup, description: String = "",
         treatment: String = "", date: Date = Date(), resolvedDate: Date? = nil,
         isResolved: Bool = false, cost: Double = 0, vetName: String = "") {
        self.id = id
        self.birdId = birdId
        self.birdName = birdName
        self.issueType = issueType
        self.description = description
        self.treatment = treatment
        self.date = date
        self.resolvedDate = resolvedDate
        self.isResolved = isResolved
        self.cost = cost
        self.vetName = vetName
    }
}

struct Coop: Identifiable, Codable {
    var id: String
    var name: String
    var capacity: Int
    var currentOccupancy: Int
    var description: String
    var features: [String]
    var lastCleaned: Date?
    var notes: String

    init(id: String = UUID().uuidString, name: String, capacity: Int,
         currentOccupancy: Int = 0, description: String = "",
         features: [String] = [], lastCleaned: Date? = nil, notes: String = "") {
        self.id = id
        self.name = name
        self.capacity = capacity
        self.currentOccupancy = currentOccupancy
        self.description = description
        self.features = features
        self.lastCleaned = lastCleaned
        self.notes = notes
    }

    var occupancyPercentage: Double {
        guard capacity > 0 else { return 0 }
        return Double(currentOccupancy) / Double(capacity)
    }
}

// MARK: - Activity
struct ActivityLog: Identifiable, Codable {
    var id: String
    var type: ActivityType
    var title: String
    var detail: String
    var date: Date

    enum ActivityType: String, Codable {
        case birdAdded, birdRemoved, eggRecord, feedRecord, healthRecord,
             breedingPair, hatchRecord, coopAdded, groupAdded, userLogin
        var icon: String {
            switch self {
            case .birdAdded: return "plus.circle.fill"
            case .birdRemoved: return "minus.circle.fill"
            case .eggRecord: return "circle.fill"
            case .feedRecord: return "bag.fill"
            case .healthRecord: return "cross.circle.fill"
            case .breedingPair: return "heart.fill"
            case .hatchRecord: return "star.fill"
            case .coopAdded: return "house.fill"
            case .groupAdded: return "person.3.fill"
            case .userLogin: return "person.crop.circle.fill"
            }
        }
        var color: Color {
            switch self {
            case .birdAdded, .birdRemoved: return .dbGreen
            case .eggRecord: return Color(hex: "#E8A020")
            case .feedRecord: return Color(hex: "#7B4F2E")
            case .healthRecord: return Color(hex: "#E53E3E")
            case .breedingPair, .hatchRecord: return Color(hex: "#805AD5")
            case .coopAdded: return Color(hex: "#3A9BD5")
            case .groupAdded: return Color(hex: "#52A865")
            case .userLogin: return Color(hex: "#A09E98")
            }
        }
    }

    init(id: String = UUID().uuidString, type: ActivityType, title: String,
         detail: String = "", date: Date = Date()) {
        self.id = id
        self.type = type
        self.title = title
        self.detail = detail
        self.date = date
    }
}
