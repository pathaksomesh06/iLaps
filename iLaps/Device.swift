//
//  Device.swift
//  iLaps
//
//  Created by Somesh Pathak on 28/04/2025.
//

import Foundation


struct Device: Identifiable, Decodable, Hashable {
    let id: String
    let deviceName: String?
    let serialNumber: String?
    let operatingSystem: String?
    let osVersion: String?
    let complianceState: String?
    let lastSyncDateTime: String?
    let deviceType: String?
    let userPrincipalName: String?
    let deviceRegistrationState: String?
    let managementState: String?
    let enrolledDateTime: String?
    let deviceEnrollmentType: String?
    let managementAgent: String?
    let ownerType: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case deviceName
        case serialNumber
        case operatingSystem
        case osVersion
        case complianceState
        case lastSyncDateTime
        case deviceType
        case userPrincipalName
        case deviceRegistrationState
        case managementState
        case enrolledDateTime
        case deviceEnrollmentType
        case managementAgent
        case ownerType
    }
}
