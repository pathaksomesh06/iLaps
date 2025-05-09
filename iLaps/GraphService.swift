import Foundation

enum GraphError: Error {
    case invalidURL
    case noData
    case httpError(Int)
}

/// Response type for Microsoft Graph list operations
struct GraphListResponse<T: Decodable>: Decodable {
    let value: [T]
    let nextLink: String?
    
    private enum CodingKeys: String, CodingKey {
        case value
        case nextLink = "@odata.nextLink"
    }
}

class GraphService {
    static let shared = GraphService()
    private let baseURL = "https://graph.microsoft.com/beta"
    
    private init() {}
    
    /// Lists all macOS devices managed by Intune.
    func listMacDevices(completion: @escaping (Result<[Device], Error>) -> Void) {
        print("Requesting Graph token...")
        AuthService.shared.acquireToken(scopes: [ConfigService.shared.graphScope]) { result in
            switch result {
            case .success(let token):
                print("Got Graph token, fetching devices...")
                
                // Build the query with proper filters and fields
                let query = "/deviceManagement/managedDevices?$filter=((deviceType eq 'macMDM') or (deviceType eq 'mac'))&$select=deviceName,serialNumber,managementAgent,ownerType,complianceState,deviceType,osVersion,lastSyncDateTime,userPrincipalName,id,deviceRegistrationState,managementState,enrolledDateTime,deviceEnrollmentType&$orderby=deviceName asc"
                
                guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                      let url = URL(string: "\(self.baseURL)\(encodedQuery)") else {
                    completion(.failure(GraphError.invalidURL))
                    return
                }
                
                print("Requesting URL: \(url)")
                var req = URLRequest(url: url)
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: req) { data, response, error in
                    if let error = error {
                        print("Network error: \(error)")
                        completion(.failure(error))
                        return
                    }
                    
                    if let http = response as? HTTPURLResponse {
                        print("Graph API response: \(http.statusCode)")
                        guard (200...299).contains(http.statusCode) else {
                            completion(.failure(GraphError.httpError(http.statusCode)))
                            return
                        }
                    }
                    
                    guard let data = data else {
                        print("No data received")
                        completion(.failure(GraphError.noData))
                        return
                    }
                    
                    do {
                        print("Decoding response...")
                        // Print the raw JSON for debugging
                        if let json = String(data: data, encoding: .utf8) {
                            print("Raw JSON response:")
                            print(json)
                        }
                        
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let wrapper = try decoder.decode(GraphListResponse<Device>.self, from: data)
                        print("Successfully decoded \(wrapper.value.count) devices")
                        completion(.success(wrapper.value))
                    } catch {
                        print("Decoding error: \(error)")
                        completion(.failure(error))
                    }
                }.resume()
                
            case .failure(let err):
                print("Token acquisition failed: \(err)")
                completion(.failure(err))
            }
        }
    }
    
    /// Invokes the on-demand remediation (runs the MDM-deployed shell script) on a device.
    func runRemediation(on deviceId: String, completion: @escaping (Bool) -> Void) {
        AuthService.shared.acquireToken(scopes: [ConfigService.shared.graphScope]) { result in
            switch result {
            case .success(let token):
                guard let url = URL(string: "\(self.baseURL)/deviceManagement/managedDevices/\(deviceId)/initiateOnDemandProactiveRemediation") else {
                    completion(false)
                    return
                }
                
                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let payload = ["scriptPolicyId": ConfigService.shared.scriptPolicyID]
                req.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
                
                URLSession.shared.dataTask(with: req) { _, response, error in
                    if let error = error {
                        print("Remediation network error: \(error)")
                        completion(false)
                        return
                    }
                    
                    guard let http = response as? HTTPURLResponse,
                          (200...299).contains(http.statusCode) else {
                        if let http = response as? HTTPURLResponse {
                            print("Remediation failed with status: \(http.statusCode)")
                        }
                        completion(false)
                        return
                    }
                    
                    print("Remediation successful")
                    completion(true)
                }.resume()
                
            case .failure(let err):
                print("Remediation token error: \(err)")
                completion(false)
            }
        }
    }
} 