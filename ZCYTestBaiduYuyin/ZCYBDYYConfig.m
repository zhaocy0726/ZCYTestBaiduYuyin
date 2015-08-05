//
//  ZCYBDYYConfig.m
//  ZCYTestBaiduYuyin
//
//  Created by zhaochunyang on 15/8/4.
//  Copyright (c) 2015年 zhaochunyang. All rights reserved.
//

#import "ZCYBDYYConfig.h"
#import "BDVoiceRecognitionClient.h"
#import "BDTheme.h"

@implementation ZCYBDYYConfig
@synthesize resultContinuousShow;
@synthesize playStartMusicSwitch;
@synthesize playEndMusicSwitch;
@synthesize recognitionLanguage;
@synthesize voiceLevelMeter;
@synthesize uiHintMusicSwitch;
@synthesize isNeedNLU;

- (id)init
{
    self = [super init];
    if (self) {
        resultContinuousShow = YES;
        playStartMusicSwitch = YES;
        playEndMusicSwitch = YES;
        _recognitionProperty = [NSNumber numberWithInt:EVoiceRecognitionPropertySearch];
        recognitionLanguage = EVoiceRecognitionLanguageChinese;
        voiceLevelMeter = YES;
        uiHintMusicSwitch = YES;
        isNeedNLU = NO;
        
        _theme = [BDTheme lightBlueTheme];
    }
    return self;
}

+ (ZCYBDYYConfig *)sharedInstance
{
    static ZCYBDYYConfig *_sharedInstance = nil;
    if (_sharedInstance == nil) {
        _sharedInstance = [[ZCYBDYYConfig alloc] init];
    }
    return _sharedInstance;
}

- (NSString *)composeInputModeResult:(id)obj
{
    NSMutableString *string = [[NSMutableString alloc] initWithString:@""];
    for (NSArray *result in obj) {
        NSDictionary *dic = [result objectAtIndex:0];
        NSString *candidateWord = [[dic allKeys] objectAtIndex:0];
        [string appendString:candidateWord];
    }
    return string;
}

@end
