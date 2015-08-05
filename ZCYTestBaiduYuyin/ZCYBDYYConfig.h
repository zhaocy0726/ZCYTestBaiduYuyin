//
//  ZCYBDYYConfig.h
//  ZCYTestBaiduYuyin
//
//  Created by zhaochunyang on 15/8/4.
//  Copyright (c) 2015年 zhaochunyang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BDTheme;

// @class - 公共接口和数据访问类
@interface ZCYBDYYConfig : NSObject
{
    /**
     *  开始说话提示音开关
     */
    BOOL playStartMusicSwitch;
    /**
     *  结束说话提示音开关
     */
    BOOL playEndMusicSwitch;
    /**
     *  选择识别的语言类型
     */
    int recognitionLanguage;
    /**
     *  是否开启连续上屏
     */
    BOOL resultContinuousShow;
    /**
     *  音量级别开关
     */
    BOOL voiceLevelMeter;
    /**
     *  识别控件提示音开关
     */
    BOOL uiHintMusicSwitch;
    /**
     *  是否需要开启NLU
     */
    BOOL isNeedNLU;
}

#pragma mark -
#pragma mark ---------- 属性 ----------

/**
 *  识别模式
 */
@property (nonatomic, strong) NSNumber *recognitionProperty;
/**
 *  开始说话提示音开关
 */
@property (nonatomic) BOOL playStartMusicSwitch;
/**
 *  结束说话提示音开关
 */
@property (nonatomic) BOOL playEndMusicSwitch;
/**
 *  选择识别的语言类型
 */
@property (nonatomic) int recognitionLanguage;
/**
 *  是否开启连续上屏
 */
@property (nonatomic) BOOL resultContinuousShow;
/**
 *  音量级别开关
 */
@property (nonatomic) BOOL voiceLevelMeter;
/**
 *  识别控件提示音开关
 */
@property (nonatomic) BOOL uiHintMusicSwitch;
/**
 *  是否需要开启NLU
 */
@property (nonatomic) BOOL isNeedNLU;
@property (nonatomic, strong) BDTheme *theme;

#pragma mark -
#pragma mark ---------- 方法 ----------

// 实现单例方法
+ (ZCYBDYYConfig *)sharedInstance;

// 组织输入模式下返回
- (NSString *)composeInputModeResult:(id)obj;

@end
