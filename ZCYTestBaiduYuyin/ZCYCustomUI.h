//
//  ZCYCustomUI.h
//  ZCYTestBaiduYuyin
//
//  Created by zhaochunyang on 15/8/4.
//  Copyright (c) 2015年 zhaochunyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// VoiceRecognitionViewController的UI布局
@interface ZCYCustomUI : NSObject

+ (ZCYCustomUI *)sharedInstance;

// --UI布局方法
- (CGRect)VRBackgroundFrame;
- (CGRect)VRRecordTintWordFrame;
- (CGRect)VRRecognizeTintWordFrame;
- (CGRect)VRLeftButtonFrame;
- (CGRect)VRRightButtonFrame;
- (CGRect)VRCenterButtonFrame;

- (CGPoint)VRRecordBackgroundCenter;
- (CGPoint)VRRecognizeBackgroundCenter;
- (CGPoint)VRTintWordCenter;
- (CGPoint)VRCenterButtonCenter;

- (CGRect)VRDemoPicerViewFrame;
- (CGRect)VRDemoPicerBackgroundViewFrame;
- (CGRect)VRDemoWebViewFrame;

@end
