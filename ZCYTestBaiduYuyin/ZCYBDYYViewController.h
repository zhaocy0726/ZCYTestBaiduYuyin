//
//  ViewController.h
//  ZCYTestBaiduYuyin
//
//  Created by zhaochunyang on 15/8/3.
//  Copyright (c) 2015年 zhaochunyang. All rights reserved.
//

#import <UIKit/UIKit.h>
/**
 *  使用识别UI
 */
#import "BDRecognizerViewController.h"
#import "BDRecognizerViewDelegate.h"
/**
 *  使用识别接口
 */
#import "BDVRFileRecognizer.h"
/**
 *  对音频数据或音频文件直接进行识别
 */
#import "BDVRRawDataRecognizer.h"
#import "BDVRDataUploader.h"

@class ZCYCustomRecogntionViewController;

@interface ZCYBDYYViewController : UIViewController<BDRecognizerViewDelegate, BDVRDataUploaderDelegate, MVoiceRecognitionClientDelegate>

/**
 *  识别UI
 */
@property (strong, nonatomic) IBOutlet UIButton *buttonUIVoiceRecogntion;
/**
 *  语音识别
 */
@property (strong, nonatomic) IBOutlet UIButton *buttonVoiceRecogntion;
/**
 *  状态通知
 */
@property (strong, nonatomic) IBOutlet UITextView *textViewStatusNotification;
/**
 *  识别结果
 */
@property (strong, nonatomic) IBOutlet UITextView *textViewRecogntionResult;

@property (nonatomic, strong) ZCYCustomRecogntionViewController *audioViewController;
@property (nonatomic, strong) BDRecognizerViewController *recognizerViewController;
@property (nonatomic, strong) BDVRRawDataRecognizer *rawDataRecognizer;
@property (nonatomic, strong) BDVRFileRecognizer *fileRecognizer;
@property (nonatomic, strong) BDVRDataUploader *dataUploader;

#pragma mark - 
#pragma mark ---------- log & result ----------

- (void)logOutToContinusManualResult:(NSString *)result;
- (void)logOutToManualResult:(NSString *)result;
- (void)logOutToLogView:(NSString *)log;

@end

