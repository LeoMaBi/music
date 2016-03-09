//
//  PlayerNetWorkTool.swift
//  Player
//
//  Created by LeoMabi on 15/12/1.
//  Copyright © 2015年 LeoMabi. All rights reserved.
//

import UIKit
import Alamofire

protocol HttpProtocol{
    func didRecieveResults(results:NSDictionary)
}


class PlayerNetWorkTool: NSObject {

    var delegate:HttpProtocol?
    func search(url:String){
        
        Alamofire.request(.GET, url).responseJSON { (Response) -> Void in
            let json = Response.result.value
            self.delegate?.didRecieveResults(json as! NSDictionary)
        }
     }
}