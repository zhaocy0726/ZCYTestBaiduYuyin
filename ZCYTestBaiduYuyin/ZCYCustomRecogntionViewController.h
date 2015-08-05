//
//  ZCYCustomRecogntionViewController.h
//  ZCYTestBaiduYuyin
//
//  Created by zhaochunyang on 15/8/4.
//  Copyright (c) 2015年 zhaochunyang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDVoiceRecognitionClient.h"

// 向前声明
@class ZCYBDYYViewController;

// 语音搜索界面的实现类
@interface ZCYCustomRecogntionViewController : UIViewController<MVoiceRecognitionClientDelegate>
{
    UIImageView *_dialog;
    ZCYBDYYViewController *clientViewController;
    
    NSTimer *_voiceLevelMeterTimer; // 获取语音音量界面定时器
}

@property (nonatomic, strong) UIImageView *dialog;
@property (nonatomic, strong) ZCYBDYYViewController *clientViewController;
@property (nonatomic, strong) NSTimer *voiceLevelMeterTimer;

@end
