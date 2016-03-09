//
//  PlayerImageView.swift
//  Player
//
//  Created by LeoMabi on 15/11/30.
//  Copyright © 2015年 LeoMabi. All rights reserved.
//

import UIKit



class PlayerImageView: UIImageView {
    
    var albumView:UIImageView?
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.clipsToBounds = true
        self.layer.cornerRadius = self.frame.size.width/2
        self.albumView = UIImageView(frame: CGRectMake(self.frame.size.width / 2 - 94, self.frame.size.height / 2 - 94, 188, 188))
        //裁剪多出的部分(多出父类的部分）
        self.albumView?.clipsToBounds = true
        self.albumView?.layer.cornerRadius = (albumView?.frame.width)! / 2.0
        self.addSubview(self.albumView!)
        
    }
    
    func starRotating() {
        let rotateAni = CABasicAnimation(keyPath: "transform.rotation")
        rotateAni.fromValue = 0.0
        rotateAni.toValue = M_PI * 2.0
        rotateAni.duration = 20.0
        rotateAni.repeatCount = MAXFLOAT
        self.layer.addAnimation(rotateAni, forKey: nil)
    }
    
//    func setAlbumImage(image:UIImage) {
//        
//        self.albumView?.frame = CGRectMake(self.frame.size.width / 2 - 81, self.frame.size.height / 2 - 81, 162, 162)
//        
//        //custom albumView
//        self.albumView?.clipsToBounds = true
//        self.albumView?.layer.cornerRadius = (albumView?.frame.width)! / 2.0
//        
//        self.addSubview(self.albumView!)
//    }

    func stopRotate() {
        self.layer.removeAllAnimations()
    }
    
    func pauseRotate() {
        let pausedTime = self.layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
        self.layer.speed = 0.0
        self.layer.timeOffset = pausedTime
    }
    
    func resumeRotate() {
        let pausedTime = self.layer.timeOffset
        self.layer.speed = 1.0
        self.layer.timeOffset = 0.0
        self.layer.beginTime = 0.0
        let timeSincePause = self.layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
        layer.beginTime = timeSincePause
        
    }

}
