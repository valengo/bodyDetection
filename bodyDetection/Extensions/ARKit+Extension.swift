//
//  ARExtensions.swift
//  bodyDetection
//
//  Created by Andressa Valengo on 22/10/19.
//  Copyright © 2019 Andressa Valengo. All rights reserved.
//

import Foundation
import ARKit

extension ARSkeleton.JointName {
    
    // from bottom to top
    @available(iOS 13.0, *)
    public static let spine2 = ARSkeleton.JointName(rawValue: "spine_2_joint")
    
    @available(iOS 13.0, *)
    public static let spine3 = ARSkeleton.JointName(rawValue: "spine_3_joint")
    
    @available(iOS 13.0, *)
    public static let spine4 = ARSkeleton.JointName(rawValue: "spine_4_joint")
    
    @available(iOS 13.0, *)
    public static let spine5 = ARSkeleton.JointName(rawValue: "spine_5_joint")
    
    @available(iOS 13.0, *)
    public static let spine6 = ARSkeleton.JointName(rawValue: "spine_6_joint")
    
    @available(iOS 13.0, *)
    public static let spine7 = ARSkeleton.JointName(rawValue: "spine_7_joint")
    
    // from bottom to top
    @available(iOS 13.0, *)
    public static let neck1 = ARSkeleton.JointName(rawValue: "neck_1_joint")
    
    @available(iOS 13.0, *)
    public static let neck2 = ARSkeleton.JointName(rawValue: "neck_2_joint")
    
    @available(iOS 13.0, *)
    public static let neck3 = ARSkeleton.JointName(rawValue: "neck_3_joint")
    
    @available(iOS 13.0, *)
    public static let neck4 = ARSkeleton.JointName(rawValue: "neck_4_joint")
    
    @available(iOS 13.0, *)
    public static let rigthArm = ARSkeleton.JointName(rawValue: "right_arm_joint")
    
    @available(iOS 13.0, *)
    public static let leftArm = ARSkeleton.JointName(rawValue: "left_arm_joint")
}
