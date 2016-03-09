//
//  ChannelTableViewController.swift
//  Player
//
//  Created by LeoMabi on 15/11/30.
//  Copyright © 2015年 LeoMabi. All rights reserved.
//

import UIKit
import KGFloatingDrawer



class ChannelTableViewController: UITableViewController,HttpProtocol{
    
    var delegate:ChaneelProtocol?
    
 //   var channelList:NSArray=NSArray()
    
    var channelList:[NSDictionary] = [NSDictionary]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    func didRecieveResults(results: NSDictionary){
        if results["channels"] != nil{
            self.channelList = results["channels"] as! [NSDictionary]
            self.tableView.reloadData()
        }
    }

    private let mNetWorkTool : PlayerNetWorkTool = PlayerNetWorkTool()
    private let mChannelListUrl: String = "http://www.douban.com/j/app/radio/channels"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.mNetWorkTool.delegate = self
        self.mNetWorkTool.search(self.mChannelListUrl)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
     // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.channelList.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "reuse")
        cell.textLabel?.text = self.channelList[indexPath.row].objectForKey("name") as? String
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        (UIApplication.sharedApplication().delegate as! AppDelegate).drawerViewController.closeDrawer(KGDrawerSide.Right, animated: true) { (finished) -> Void in
            
        }
        let dic = self.channelList[indexPath.row]
//        let channel_id = dic.objectForKey("channel_id")as! String
        if let a = dic["channel_id"] as? NSNumber{
            let  channel_id = a.stringValue
            self.delegate?.onChannelChange(channel_id)
        } else{
            let channel_id = dic.objectForKey("channel_id")as! String
            self.delegate?.onChannelChange(channel_id)

        }
   
       }

  }

