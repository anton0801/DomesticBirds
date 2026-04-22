import Foundation
import Supabase

final class SupabaseIntegrityCheck: IntegrityCheck {
    
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://uiixhhvarbkzvpjcwsgk.supabase.co")!,
            supabaseKey: "sb_publishable_5j5P3JUmXRY1M4rlA5RWyw_MqEb99Xw"
        )
    }
    
    func verify() async -> Result<Bool, ValidationError> {
        do {
            let rows: [CheckRow] = try await client
                .from("validation")
                .select()
                .limit(1)
                .execute()
                .value
            
            guard let row = rows.first else {
                return .success(false)
            }
            
            return .success(row.isValid)
            
        } catch {
            print("🐔 [DomesticBirds] Validation error: \(error)")
            return .failure(.checkFailed)
        }
    }
}

struct CheckRow: Codable {
    let id: Int?
    let isValid: Bool
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case isValid = "is_valid"
        case createdAt = "created_at"
    }
}
