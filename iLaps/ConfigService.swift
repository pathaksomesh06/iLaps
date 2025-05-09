//
//  ConfigService.swift
//  iLaps
//
//  Created by Somesh Pathak on 28/04/2025.
//

import Foundation

public class ConfigService {
    public static let shared = ConfigService()

    // Azure AD configuration
    public let clientID: String
    public let tenantID: String
    public let redirectURI: String
    
    // Microsoft Graph configuration
    public let graphScope: String
    public let scriptPolicyID: String
    
    // Azure Key Vault configuration
    public let keyVaultScope: String
    public let vaultName: String
    public let keyVaultURL: String

    private init() {
        print("Initializing ConfigService...")
        let defaults = UserDefaults.standard
        
        // List all persistent domains to help debug
        print("Available persistent domains:")
        defaults.dictionaryRepresentation().keys.forEach { domain in
            print("- \(domain)")
        }
        
        // Extract values directly from UserDefaults (populated by MDM)
        guard let client = defaults.string(forKey: "ClientID"),
              let tenant = defaults.string(forKey: "TenantID"),
              var redirect = defaults.string(forKey: "CredentialRedirectURI"),
              let gscope = defaults.string(forKey: "GraphScope"),
              let kvscope = defaults.string(forKey: "KeyVaultScope"),
              let vault = defaults.string(forKey: "VaultName"),
              let policy = defaults.string(forKey: "ScriptPolicyID") else {
            print("Failed to extract configuration values:")
            print("ClientID present: \(defaults.string(forKey: "ClientID") != nil)")
            print("TenantID present: \(defaults.string(forKey: "TenantID") != nil)")
            print("CredentialRedirectURI present: \(defaults.string(forKey: "CredentialRedirectURI") != nil)")
            print("GraphScope present: \(defaults.string(forKey: "GraphScope") != nil)")
            print("KeyVaultScope present: \(defaults.string(forKey: "KeyVaultScope") != nil)")
            print("VaultName present: \(defaults.string(forKey: "VaultName") != nil)")
            print("ScriptPolicyID present: \(defaults.string(forKey: "ScriptPolicyID") != nil)")
            fatalError("Missing or incomplete MDM configuration")
        }
        
        
        if redirect.contains("ilaps") {
            redirect = redirect.replacingOccurrences(of: "ilaps", with: "iLaps")
        }
        
        // Store the configuration values
        self.clientID = client
        self.tenantID = tenant
        self.redirectURI = redirect
        self.graphScope = gscope
        self.keyVaultScope = kvscope
        self.vaultName = vault
        self.scriptPolicyID = policy
        
        // Construct Key Vault URL from vault name
        self.keyVaultURL = "https://\(vault).vault.azure.net"
        
        print("Configuration loaded successfully:")
        print("- Client ID: \(clientID)")
        print("- Tenant ID: \(tenantID)")
        print("- Redirect URI: \(redirectURI)")
        print("- Graph Scope: \(graphScope)")
        print("- Key Vault Scope: \(keyVaultScope)")
        print("- Key Vault Name: \(vaultName)")
        print("- Key Vault URL: \(keyVaultURL)")
        print("- Script Policy ID: \(scriptPolicyID)")
    }
}
