//
//  ViewController.swift
//  Player
//
//  Created by LeoMabi on 15/11/29.
//  Copyright © 2015年 LeoMabi. All rights reserved.
//

import UIKit
import Alamofire
import KGFloatingDrawer
import MediaPlayer


struct PlayStatus {
    static let PLAYING:Int  = 0
    static let PAUSE:Int    = 1
    static let STOP:Int     = 2
}


protocol ChaneelProtocol{
    func onChannelChange(id:String)
}

class PlayerViewController: UIViewController ,ChaneelProtocol ,HttpProtocol,UITableViewDataSource,UIActionSheetDelegate{
    
    @IBOutlet var mMainBGImageView: UIImageView!
    @IBOutlet var mAlbumImageView: PlayerImageView!
    @IBOutlet var mTitleLabel: UILabel!
    @IBOutlet var mPreBtn: UIButton!
    @IBOutlet var mPlayBtn: UIButton!
    @IBOutlet var mNextBtn: UIButton!
    @IBOutlet var PlayedTime: UILabel!
    @IBOutlet var AllTime: UILabel!
//    @IBOutlet var mPlayProgressBar: UIProgressView!
    
    @IBOutlet var mSlider: UISlider!
    @IBOutlet var mArtist: UILabel!
    @IBOutlet var MTitleView: UIView!
    @IBOutlet var mLrcTable: UITableView!
    
    var mNeedImage: UIImageView!
    var needleOriginTransform : CGAffineTransform?
    var mSongsArray : [NSDictionary] = [NSDictionary]()
    var mPhotoArray = Dictionary<String, UIImage>()
    let mNetWorkTool : PlayerNetWorkTool = PlayerNetWorkTool()
    
    let mSongListUrl : String = "http://douban.fm/j/mine/playlist?type=n&pb=128&from=mainsite&channel="
    let mLyricUrl : String = "http://geci.me/api/lyric/"
    
    var mCurrentSongIndex = 0
    var mPlayingStatus : Int = PlayStatus.STOP
    var mUpdateTimer : NSTimer!
    
    var mLRCDictinary : [String : String] = [String : String]()
    var mTimeArray : [String] = [String]()
    var mIsLRCPrepared : Bool = false
    var mLineNumber : Int = -1
    var sort : Int = 1
    var isAutoDone : Bool = true
   
    var audioPlayer : MPMoviePlayerController = MPMoviePlayerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mSlider.setThumbImage(UIImage(named: "cm2_btn_radio_slt"), forState: UIControlState.Normal)
        //滑动手势-左
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: "handleSwipeGesture:")
        swipeLeftGesture.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeLeftGesture)
        //滑动手势-右
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: "handleSwipeGesture:")
        swipeRightGesture.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRightGesture)
        
        //毛玻璃
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let visualView = UIVisualEffectView(effect: blurEffect)
        visualView.alpha = 0.95
        visualView.frame = UIScreen.mainScreen().bounds
        self.mMainBGImageView.addSubview(visualView)
        
        //歌词
        self.mLrcTable.userInteractionEnabled = false
        self.mLrcTable.backgroundView = nil
        self.mLrcTable.backgroundView = UIView()
        self.mLrcTable.backgroundView?.backgroundColor = UIColor.clearColor()
        self.mLrcTable.backgroundColor = UIColor.clearColor()
        self.mLrcTable.dataSource = self
        self.mLrcTable.separatorColor = UIColor.clearColor()
        
        //唱针
        let screenBounds = UIScreen.mainScreen().bounds
        self.mNeedImage = UIImageView(frame: CGRectMake((screenBounds.width - 121) / 2 + 121 * 0.25, 33, 121, 197))
        self.mNeedImage.image = UIImage(named: "cm2_play_needle_play-ip6")
        self.view.addSubview(self.mNeedImage)
        self.needleOriginTransform = self.mNeedImage.transform
        self.setAnchorPoint(CGPointMake(0.25, 0.16), forView: self.mNeedImage)
        self.rotateNeedle(false)

        self.mNetWorkTool.delegate = self
        for var i = 0; i < 5; i++ {
            //print("\(i)")
            self.mNetWorkTool.search(self.mSongListUrl + "0")
        }
        self.view.bringSubviewToFront(MTitleView)
        
        //播放结束通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playFinish", name: MPMoviePlayerPlaybackDidFinishNotification, object: self.audioPlayer)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sliderValueChange(sender: UISlider) {
        
        
    }
    //MARK: - 滑动手势
    func handleSwipeGesture(sender: UISwipeGestureRecognizer) {
        let diretion = sender.direction
        //判断方向
        switch (diretion) {
        case UISwipeGestureRecognizerDirection.Left:
            self.playPre()
            print("left")
            break
        case UISwipeGestureRecognizerDirection.Right:
            print("right")
            self.playNext()
            break
        case UISwipeGestureRecognizerDirection.Up:
            print("up")
            break
        case UISwipeGestureRecognizerDirection.Down:
            print("down")
            break
        default:
            break
        }
    }

    
    //MARK: - Button Click Actions
    @IBAction func onPreClicked(sender: AnyObject) {
        self.playPre()
    }
    
    @IBAction func onPlayClicked(sender: AnyObject) {
        switch self.mPlayingStatus{
        case PlayStatus.STOP:
            self.playMusic(self.mSongsArray[self.mCurrentSongIndex])
            self.mPlayBtn.setImage(UIImage(named: "cm2_fm_btn_pause"), forState: UIControlState.Normal)
            break
        case PlayStatus.PLAYING:
            self.pause()
            self.mPlayBtn.setImage(UIImage(named: "cm2_fm_btn_play"), forState: UIControlState.Normal)
            break
        case PlayStatus.PAUSE:
            self.resume()
            self.mPlayBtn.setImage(UIImage(named: "cm2_fm_btn_pause"), forState: UIControlState.Normal)
            break
        default:
            break
        }
    }
    
    @IBAction func onNextClicked(sender: AnyObject) {
        self.playNext()
    }
    
    @IBAction func sortClick(sender : AnyObject) {
        sort++
        //切换图片
        if sort == 1 { //顺序播放
            sender.setImage(UIImage(named: "cm2_icn_loop"), forState: UIControlState.Normal)
        } else if sort == 2 { //随机播放
            sender.setImage(UIImage(named: "cm2_icn_shuffle"), forState: UIControlState.Normal)
        } else if sort == 3{ //单曲播放
            sender.setImage(UIImage(named: "cm2_icn_one"), forState: UIControlState.Normal)
        } else if sort > 3 { //返回顺序播放
            sort = 1
            sender.setImage(UIImage(named: "cm2_icn_loop"), forState: UIControlState.Normal)
        }
        
    }

    
  @IBAction func rightViewShow(sender: UIButton) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.drawerViewController.toggleDrawer(KGDrawerSide.Right, animated: true) { (finished) -> Void in
        }
    }

    // MARK: - Data Request
    func didRecieveResults(results: NSDictionary) {
        //KVNProgress.dismiss()
        self.mSongsArray += results["song"] as! [NSDictionary]
        self.setupMusicInfo(self.mSongsArray[0])
        //Load Image
        let imgUrl:String = self.mSongsArray[0].valueForKey("picture") as! String
        loadImage(imgUrl)
        loadLRC(self.mSongsArray[0].valueForKey("title") as! String, artist: self.mSongsArray[0].valueForKey("artist") as! String)
        self.isAutoDone = false

    }
    
    func loadImage(url:String){
        let imgURL:NSURL = NSURL(string: url)!
        let request:NSURLRequest = NSURLRequest(URL: imgURL)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {
            (response, data, error) -> Void  in
            let img = UIImage(data: data!)
            self.mMainBGImageView.image = img
            self.mAlbumImageView.albumView?.image = img
            self.mPhotoArray[url] = img
        })
    }
    // MARK: - Play Control
    func setupMusicInfo(songDic:NSDictionary) {
        mUpdateTimer?.invalidate()
        PlayedTime.text = "00:00"
        self.AllTime.text = MMSS(songDic.valueForKey("length") as! Int)
        mTitleLabel.text = songDic.valueForKey("title") as? String
        mArtist.text = songDic.valueForKey("artist") as? String
        self.isAutoDone = true

    }
    
    func MMSS(timeNumber : Int) -> String {
        let minute : Int = timeNumber / 60
        let second : Int = timeNumber % 60
        
        var timeStr : String = ""
        if minute < 10 {
            timeStr = "0\(minute):"
        } else {
            timeStr = "0\(minute):"
        }
        if second < 10 {
            timeStr+="0\(second)"
        } else {
            timeStr+="\(second)"
        }
        
        return timeStr
    }

    
    func playMusic(songDic:NSDictionary) {
        //Claer View
        self.setupMusicInfo(songDic)
        let imgUrl:String = songDic.valueForKey("picture") as! String
        self.loadImage(imgUrl)
        
        //Play Music
        AFSoundManager.sharedManager().startStreamingRemoteAudioFromURL(songDic.valueForKey("url") as! String) { (percentage, elapsedTime, timeRemaining, error, finished) -> Void in
            if error != nil {
                //print(error)
            } else {
                if finished {
                    
                } else {
                    if percentage > 0 {
                        
                        self.mSlider.value = CFloat(percentage) * 0.01
//                        self.mSlider.setProgress(CFloat(percentage) * 0.01, animated: true)
                    }else{
                        self.mSlider.value = 0
//                        self.mSlider.setProgress(0, animated: true)
                    }
                    self.PlayedTime.text = self.MMSS(Int(elapsedTime))
                    if self.mIsLRCPrepared {
                        self.updateLRC(elapsedTime)
                    }
                }
            }
        }
        self.mAlbumImageView.starRotating()
        self.rotateNeedle(true)
        self.mPlayingStatus = PlayStatus.PLAYING
    }
  
    func pause() {
        self.mAlbumImageView.pauseRotate()
        self.rotateNeedle(false)
        AFSoundManager.sharedManager().pause()
        self.mPlayingStatus = PlayStatus.PAUSE
        
    }
    
    func resume() {
        self.mAlbumImageView.resumeRotate()
        self.rotateNeedle(true)
        AFSoundManager.sharedManager().resume()
        self.mPlayingStatus = PlayStatus.PLAYING
    }
    
    func playNext() {
        self.isAutoDone = false
        mCurrentSongIndex++
        if self.mCurrentSongIndex > self.mSongsArray.count - 1 {
            mCurrentSongIndex = 0
        }
        self.mPlayBtn.setImage(UIImage(named: "cm2_fm_btn_pause"), forState: UIControlState.Normal)
        let song = self.mSongsArray[self.mCurrentSongIndex]
        self.mAlbumImageView.resumeRotate()
        self.playMusic(song)
        //Load Image
        let imgUrl:String = song.valueForKey("picture") as! String
        loadImage(imgUrl)
        loadLRC(song.valueForKey("title") as! String, artist: song.valueForKey("artist") as! String)

    }
    
    func playPre() {
        self.isAutoDone = false
        mCurrentSongIndex--
        if self.mCurrentSongIndex < 0 {
            self.mCurrentSongIndex = self.mSongsArray.count - 1
        }
        let song = self.mSongsArray[self.mCurrentSongIndex]
        self.mAlbumImageView.resumeRotate()
        self.mPlayBtn.setImage(UIImage(named: "cm2_fm_btn_pause"), forState: UIControlState.Normal)
        self.playMusic(song)
        loadLRC(song.valueForKey("title") as! String, artist: song.valueForKey("artist") as! String)
    }

//    
//    func musicFinished(notification:NSNotification){
//        playNext()
//    }
    
    func playFinish() {
        self.mAlbumImageView.stopRotate()
        
        if self.isAutoDone {
            
            if sort == 1 { //顺序播放
                
                self.playNext()
                
            } else if sort == 2 { //随机播放
                self.mCurrentSongIndex = random() % (self.mSongsArray.count)
                let song = self.mSongsArray[self.mCurrentSongIndex]
                self.audioPlayer.pause()
                self.playMusic(song)
                //Load Image
                let imgUrl:String = song.valueForKey("picture") as! String
                loadImage(imgUrl)
                loadLRC(song.valueForKey("title") as! String, artist: song.valueForKey("artist") as! String)
            } else if sort == 3 { //单曲播放
                let song = self.mSongsArray[self.mCurrentSongIndex]
                self.audioPlayer.pause()
                self.playMusic(song)
                //Load Image
                let imgUrl:String = song.valueForKey("picture") as! String
                loadImage(imgUrl)
                loadLRC(song.valueForKey("title") as! String, artist: song.valueForKey("artist") as! String)
            } else if sort > 3 { //返回顺序播放
                
                sort = 1
                self.playNext()
            }
            
        } else {
            self.isAutoDone = true
        }
    }
    
    
    // MARK: - Animate
    func rotateNeedle(isPlaying : Bool) {
        
        UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            if !isPlaying{
                self.mNeedImage.transform = CGAffineTransformMakeRotation(-CGFloat(M_PI / 6))
            }else{
                self.mNeedImage.transform = self.needleOriginTransform!
            }
            }) { (finished) -> Void in
                
        }
    }
   
    func setAnchorPoint(anchorPoint: CGPoint, forView view :UIView ) {
        var newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y)
        
        newPoint = CGPointApplyAffineTransform(newPoint, view.transform)
        oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform)
        
        var position = view.layer.position
        position.x -= oldPoint.x
        position.x += newPoint.y
        
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        view.layer.position = position
        view.layer.anchorPoint = anchorPoint

    }
    
    // MARK: - Channel Delegate
    func onChannelChange(channel_id: String) {
        //Stop Play
        AFSoundManager.sharedManager().stop()
        self.mPlayingStatus = PlayStatus.STOP
        self.mPlayBtn.setImage(UIImage(named: "cm2_fm_btn_play"), forState: UIControlState.Normal)
        self.mSongsArray.removeAll(keepCapacity: false)

        
        //Clear View
        self.mAlbumImageView.stopRotate()
        self.rotateNeedle(false)
        
        //Load Data
        for var i = 0; i < 5; i++ {
            self.mNetWorkTool.search(self.mSongListUrl + channel_id)
        }
    }

    //MARK: - LRC Operation
    func loadLRC(name:String, artist:String) {
        self.mIsLRCPrepared = false
        let url = self.mLyricUrl + name + "/" + artist
        Alamofire.request(.GET, url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet())!, parameters: nil, encoding: ParameterEncoding.JSON, headers: nil).responseJSON { (Response) -> Void in
            
            let json = Response.result.value
            if json != nil && json?.objectForKey("count") as! Int  > 0 {
                //默认选择第一个歌词,地址赋给lrcUrl
                let lrcUrl = (json?.objectForKey("result") as! [NSDictionary])[0].objectForKey("lrc") as! String
                let tempArrA = lrcUrl.componentsSeparatedByString("/")
                let lrcPath = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]  ) + "/" + tempArrA[tempArrA.count - 1]
                if NSFileManager.defaultManager().fileExistsAtPath(lrcPath) {
                    self.prepareLRC(lrcPath)
                } else {
                    let destination = Alamofire.Request.suggestedDownloadDestination(directory: .DocumentDirectory, domain: .UserDomainMask)
                    Alamofire.download(.GET, lrcUrl, destination: destination).response(completionHandler: { (_, response, data, error) -> Void in
                        //print(data)
                        if error == nil{
                            self.prepareLRC(lrcPath)
                        } else {
                           print("歌词下载失败")

                        }
                    })
                }
            }else{
                print("歌词未收录")
            }
         }
        
    }
    

    func prepareLRC(lrcPath:String) {
        do{
            let contentStr = try NSString(contentsOfFile: lrcPath, encoding: NSUTF8StringEncoding)
            print("contentstr is ",contentStr)
            let lrcArray = contentStr.componentsSeparatedByString("\n")
//            print("lrcArray is ",lrcArray)

            self.mLRCDictinary = [String : String]()
            self.mTimeArray = [String]()
          
            for line in lrcArray {
                var lineArr = line.componentsSeparatedByString("]")
//                print("line is ",line)


                if lineArr[0].characters.count > 8 {
                    let str1 = (line as NSString).substringWithRange(NSRange(location: 3,length: 1))
                    let str2 = (line as NSString).substringWithRange(NSRange(location: 6,length: 1))
                    if str1 == ":" && str2 == "." {
                        let lrcStr = lineArr[1]
//                        print("lrcStr is ",lrcStr)
                        let timeStr = (lineArr[0] as NSString).substringWithRange(NSRange(location: 1, length: 5))
//                        print("timeStr is ",timeStr)

                        self.mLRCDictinary[timeStr] = lrcStr
                        self.mTimeArray.append(timeStr)
                    }
                }
            }

        }catch _
        {
            
        }
        print("lrc load finished!")
        self.mIsLRCPrepared = true
        self.mLrcTable.reloadData()
    }
    
    func updateLRC(currentTime:CGFloat) {
        for i in 0..<self.mLRCDictinary.count {
            var timeArr = self.mTimeArray[i].componentsSeparatedByString(":") as [String]
            let time = CGFloat(Int(timeArr[0])!) * 60 + CGFloat(Int(timeArr[1])!)
            if i + 1 < self.mTimeArray.count {
                var timeArr1 = self.mTimeArray[i + 1].componentsSeparatedByString(":") as [String]
                let time1 = CGFloat(Int(timeArr1[0])!) * 60 + CGFloat(Int(timeArr1[1])!)
                if currentTime > time && currentTime < time1 {
                    self.mLineNumber = i
                    self.mLrcTable.reloadData()
                    self.mLrcTable.selectRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0), animated: true, scrollPosition: UITableViewScrollPosition.Middle)
                }
            }
        }
    }
    
    //MARK: - Table Delegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mTimeArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("lrcCell") as! SRLrcCell
        cell.mTitleLable.text = self.mLRCDictinary[self.mTimeArray[indexPath.row]]
        cell.backgroundColor = UIColor.clearColor()
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        cell.mTitleLable.numberOfLines = 0
        cell.mTitleLable.lineBreakMode = NSLineBreakMode.ByWordWrapping
        
        if self.mLineNumber == indexPath.row {
            cell.mTitleLable.font = UIFont.systemFontOfSize(14)
            cell.mTitleLable.textColor = UIColor.redColor()
        } else {
            cell.mTitleLable.font = UIFont.systemFontOfSize(12)
            cell.mTitleLable.textColor = UIColor.whiteColor()
        }
        
        return cell
    }
    
//    override func preferredStatusBarStyle() -> UIStatusBarStyle {
//        return UIStatusBarStyle.LightContent
//    }
}

