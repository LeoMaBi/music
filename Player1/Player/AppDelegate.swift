//
//  AppDelegate.swift
//  Player
//
//  Created by LeoMabi on 15/11/29.
//  Copyright © 2015年 LeoMabi. All rights reserved.
//

import UIKit
import KGFloatingDrawer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = drawerViewController
        window?.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - Drawer
    private var _drawerViewController:KGDrawerViewController?
    
    var drawerViewController: KGDrawerViewController{
        get {
            if let viewController = _drawerViewController{
                return viewController
            }
            return prepareDrawerViewController()
        }
    }
    
//    var _aString : String = ""
//    var aString : String {
//        get {
//            return _aString
//        }
//        set {
//            _aString = newValue
//        }
//    }
//
//    
    func prepareDrawerViewController() ->KGDrawerViewController {
        let drawerViewController = KGDrawerViewController()
        
        let centerC = viewContorllerForStoryboardId("centerContorller") as! PlayerViewController
        let rightC = viewContorllerForStoryboardId("rightController") as!  ChannelTableViewController
          //  drawerViewController.backgroundImage = UIImage(named: "2")
        
        rightC.delegate = centerC
        
        drawerViewController.centerViewController = centerC
        drawerViewController.rightViewController = rightC
        
        _drawerViewController = drawerViewController
        
        let animator = _drawerViewController!.animator
        animator.animationDuration = 0.7
        animator.initialSpringVelocity = 1.0
        animator.springDamping = 5.0
        
        return drawerViewController
        
    }
    
    private func drawerStoryboard() -> UIStoryboard{
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard
    }
    private func viewContorllerForStoryboardId(storyboardId:String) -> UIViewController{
        let viewController: UIViewController = drawerStoryboard().instantiateViewControllerWithIdentifier(storyboardId) 
        return viewController
    }

    
}
