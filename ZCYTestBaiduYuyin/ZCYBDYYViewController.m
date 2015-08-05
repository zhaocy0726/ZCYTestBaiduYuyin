//
//  ViewController.m
//  ZCYTestBaiduYuyin
//
//  Created by zhaochunyang on 15/8/3.
//  Copyright (c) 2015年 zhaochunyang. All rights reserved.
//

#import "ZCYBDYYViewController.h"
#import "ZCYBDYYConfig.h"
#import "ZCYCustomRecogntionViewController.h"

#import "BDVoiceRecognitionClient.h"
#import "BDVRUIPromptTextCustom.h"

#define API_KEY @"Sp9DNMtVMiYA3ynKAkhuAlpq" // 请修改为您在百度开发者平台申请的API_KEY
#define SECRET_KEY @"91a57f832564a3378d926af87410ab30" // 请修改您在百度开发者平台申请的SECRET_KEY

@implementation ZCYBDYYViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark ---------- 点击识别按钮 ----------

// 识别UI
- (IBAction)clickButtonUIVoiceRecogntion:(UIButton *)sender
{
    [self clean];
    
    // 创建识别控件
    BDRecognizerViewController *recognizerViewController = [[BDRecognizerViewController alloc] initWithOrigin:CGPointMake(9, 128) withTheme:[ZCYBDYYConfig sharedInstance].theme];
    
    // 全屏UI
    if ([[ZCYBDYYConfig sharedInstance].theme.name isEqualToString:@"全屏亮蓝"]) {
        recognizerViewController.enableFullScreenMode = YES;
    }
    
    recognizerViewController.delegate = self;
    self.recognizerViewController = recognizerViewController;
    
    // 设置识别参数
    [self configParamsObject];
}

// 语音识别
- (IBAction)clickButtonVoiceRecogntion:(UIButton *)sender
{
    [self clean];
    
    // 设置开发者信息
    [[BDVoiceRecognitionClient sharedInstance] setApiKey:API_KEY withSecretKey:SECRET_KEY];
    
    // 设置语音识别模式，默认是输入模式
    [[BDVoiceRecognitionClient sharedInstance] setPropertyList:@[[ZCYBDYYConfig sharedInstance].recognitionProperty]];
    
    // 设置城市ID，当识别属性包含EVoiceRecognitionPropertyMap时有效
    [[BDVoiceRecognitionClient sharedInstance] setCityID:1];
    
    // 设置是否需要语义理解，只有在搜索模式有效
    [[BDVoiceRecognitionClient sharedInstance] setConfig:@"nlu" withFlag:[ZCYBDYYConfig sharedInstance].isNeedNLU];
    
    // 开启联系人识别
//    [[BDVoiceRecognitionClient sharedInstance] setConfig:@"enable_contacts" withFlag:YES];
    
    // 设置识别语言
    [[BDVoiceRecognitionClient sharedInstance] setLanguage:[ZCYBDYYConfig sharedInstance].recognitionLanguage];
    
    // 是否打开了语音音量监听功能， 可选
    if ([ZCYBDYYConfig sharedInstance].voiceLevelMeter) {
        BOOL res = [[BDVoiceRecognitionClient sharedInstance] listenCurrentDBLevelMeter];
        // 如果监听失败， 则恢复开关
        if (res == NO) {
            [ZCYBDYYConfig sharedInstance].voiceLevelMeter = NO;
        }
    }
    else {
        [[BDVoiceRecognitionClient sharedInstance] cancelListenCurrentDBLevelMeter];
    }
    
    // 设置播放开始说话提示音开关，可选
    [[BDVoiceRecognitionClient sharedInstance] setPlayTone:EVoiceRecognitionPlayTonesRecStart isPlay:[ZCYBDYYConfig sharedInstance].playStartMusicSwitch];
    // 设置播放结束说话提示音开关，可选
    [[BDVoiceRecognitionClient sharedInstance] setPlayTone:EVoiceRecognitionPlayTonesRecEnd isPlay:[ZCYBDYYConfig sharedInstance].playEndMusicSwitch];
    
    // 创建语音识别界面，在其viewDidLoad方法中启动语音识别
    ZCYCustomRecogntionViewController *audioViewController = [[ZCYCustomRecogntionViewController alloc] initWithNibName:nil bundle:nil];
    audioViewController.clientViewController = self;
    self.audioViewController = audioViewController;
    [[UIApplication sharedApplication].keyWindow addSubview:_audioViewController.view];
}

// 音频数据识别
- (IBAction)clickButtonAudioDataRecognition:(UIButton *)sender
{
    // 开发者信息，必须修改 API_KEY 和 SECRET_KEY，这两个是在百度开发者平台申请获得的信息，没有的话不能工作
    [[BDVoiceRecognitionClient sharedInstance] setApiKey:API_KEY withSecretKey:SECRET_KEY];
    // 设置是否需要语义理解，只在搜索模式下有效
    [[BDVoiceRecognitionClient sharedInstance] setConfig:@"nlu" withFlag:[ZCYBDYYConfig sharedInstance].isNeedNLU];
    
    /* 文件识别
     NSBundle *bundle = [NSBundle mainBundle];
     NSString *recordFile = [bundle pathForResource:@"example_localRecord" ofType:@"pcm" inDirectory:nil];
     self.fileRecognizer = [[BDVRFileRecognizer alloc] initFileRecognizerWithFilePath:<#(NSString *)#> sampleRate:<#(int)#> property:<#(TBDVoiceRecognitionProperty)#> delegate:<#(id<MVoiceRecognitionClientDelegate>)#>]
     int status = [self.fileRecognizer startFileRecognition];
     if (status != EVoiceRecognitionStartWorking) {
     [self logOutToManualResult:[NSString stringWithFormat:@"错误码: %d\r\n", status]];
     return;
     }
     */
    
    // 数据识别
    self.rawDataRecognizer = [[BDVRRawDataRecognizer alloc] initRecognizerWithSampleRate:16000 property:[[ZCYBDYYConfig sharedInstance].recognitionProperty intValue] delegate:self];
    int status = [self.rawDataRecognizer startDataRecognition];
    if (status != EVoiceRecognitionStartWorking) {
        [self logOutToManualResult:[NSString stringWithFormat:@"错误码：%d\r\n", status]];
        return;
    }
    
    NSThread *fileReadThread = [[NSThread alloc] initWithTarget:self selector:@selector(fileReadThreadFunc) object:nil];
    [fileReadThread start];

    [self clean];
    [self logOutToLogView:@"音频数据识别开始\r\n开始上传数据"];
}


#pragma mark -
#pragma mark ---------- MVoiceRecognitionClient delegate ----------

// 简单实现语音识别的话 执行下面这个代理方法即可
- (void)VoiceRecognitionClientWorkStatus:(int)aStatus obj:(id)aObj
{
    switch (aStatus) {
        case EVoiceRecognitionClientWorkStatusFinish: {
            if ([[BDVoiceRecognitionClient sharedInstance] getRecognitionProperty] != EVoiceRecognitionPropertyInput) {
                NSMutableArray *audioResultData = (NSMutableArray *)aObj;
                NSMutableString *string = [[NSMutableString alloc] initWithString:@""];
                for (int i = 0; i < [audioResultData count]; i ++) {
                    [string appendFormat:@"%@\r\n", [audioResultData objectAtIndex:i]];
                }
                self.textViewRecogntionResult.text = nil;
                [self logOutToManualResult:string];
            }
            else {
                self.textViewRecogntionResult.text = nil;
                NSString *string = [[ZCYBDYYConfig sharedInstance] composeInputModeResult:aObj];
                [self logOutToManualResult:string];
            }
            [self logOutToLogView:@"识别完成"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusFlushData: {
            NSMutableString *string = [[NSMutableString alloc] initWithString:@""];
            [string appendFormat:@"%@", [aObj objectAtIndex:0]];
            self.textViewRecogntionResult.text = nil;
            [self logOutToManualResult:string];
            break;
        }
        case EVoiceRecognitionClientWorkStatusReceiveData: {
            if ([[BDVoiceRecognitionClient sharedInstance] getRecognitionProperty] == EVoiceRecognitionPropertyInput) {
                self.textViewRecogntionResult.text = nil;
                NSString *string = [[ZCYBDYYConfig sharedInstance] composeInputModeResult:aObj];
                [self logOutToManualResult:string];
            }
            break;
        }
        default:
            break;
    }
}

- (void)VoiceRecognitionClientErrorStatus:(int)aStatus subStatus:(int)aSubStatus
{
    
}

- (void)VoiceRecognitionClientNetWorkStatus:(int)aStatus
{
    
}

#pragma mark - 
#pragma mark ---------- 上传联系人 ----------

- (void)updateContacts
{
    BDVRDataUploader *dataUploader = [[BDVRDataUploader alloc] initDataUploader:self];
    self.dataUploader = dataUploader;
    [self.dataUploader setApiKey:API_KEY withSecretKey:SECRET_KEY];
    NSString *jsonString = @"[{\"name\": \"test\", \"frequency\": 1}, {\"name\": \"release\", \"frequency\": 2}]";
    [self.dataUploader uploadContactsData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    [self logOutToLogView:@"开始上传联系人..."];
}

#pragma mark ---------- BDVRDataUploader delegate

- (void)onComplete:(BDVRDataUploader *)dataUploader error:(NSError *)error
{
    if (error.code == 0) {
        [self logOutToLogView:@"联系人上传成功"];
    }
    else {
        [self logOutToLogView:[NSString stringWithFormat:@"联系人上传失败。错误码: %ld", (long)error.code]];
    }
}

#pragma mark - 
#pragma mark ---------- BDRecognizerView delegate ----------

// 识别结果返回
- (void)onEndWithViews:(BDRecognizerViewController *)aBDRecognizerViewController withResults:(NSArray *)aResults
{
    _textViewRecogntionResult.text = nil;
    
    if ([[BDVoiceRecognitionClient sharedInstance] getRecognitionProperty] != EVoiceRecognitionPropertyInput) {
        // 搜索结果为数组，例如：["公园", "公元"]
        NSMutableArray *audioResultData = (NSMutableArray *)aResults;
        NSMutableString *string = [[NSMutableString alloc] initWithString:@""];
        
        for (int i = 0; i < [audioResultData count]; i ++) {
            [string appendFormat:@"%@\r\n", [audioResultData objectAtIndex:i]];
        }
        
        _textViewRecogntionResult.text = [_textViewRecogntionResult.text stringByAppendingString:string];
        _textViewRecogntionResult.text = [_textViewRecogntionResult.text stringByAppendingString:@"\n"];
    }
    else {
        // 输入模式下的结果为带置信度的结果，示例如下：
        //  [
        //      [
        //         {
        //             "百度" = "0.6055192947387695";
        //         },
        //         {
        //             "摆渡" = "0.3625582158565521";
        //         },
        //      ]
        //      [
        //         {
        //             "一下" = "0.7665404081344604";
        //         }
        //      ],
        //   ]
        NSString *string = [[ZCYBDYYConfig sharedInstance] composeInputModeResult:aResults];
        
        _textViewRecogntionResult.text = [_textViewRecogntionResult.text stringByAppendingString:string];
        _textViewRecogntionResult.text = [_textViewRecogntionResult.text stringByAppendingString:@"\n"];
    }
}

#pragma mark - 
#pragma mark ---------- 读文件线程 ---------

- (void)fileReadThreadFunc
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *recordFile = [bundle pathForResource:@"example_localRecord" ofType:@"pcm" inDirectory:nil];
    
    int hasReadFileSize = 0;
    
    // 每次向识别器发送的数据大小建议小于4k，计算方式：采样率 * 时长 * 采样大小 / 压缩比
    // 其中采样率支持 16000 和 8000，采样率大小为 16bit，压缩比为 8，时长建议不超过1s
    int sizeToRead = 16000 * 0.080 * 16 / 8;
    while (YES) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:recordFile];
        [fileHandle seekToFileOffset:hasReadFileSize];
        NSData *data = [fileHandle readDataOfLength:sizeToRead];
        [fileHandle closeFile];
        hasReadFileSize += [data length];
        if ([data length] > 0) {
            [self.rawDataRecognizer sendDataToRecognizer:data];
        }
        else {
            [self.rawDataRecognizer allDataHasSent];
            break;
        }
    }
}

#pragma mark - 
#pragma mark ---------- 设置识别参数 ----------

- (void)configParamsObject
{
    BDRecognizerViewParamsObject *paramsObject = [[BDRecognizerViewParamsObject alloc] init];
    
    // 开发者信息，必须修改 API_KEY 和 SECRET_KEY，这两个是在百度开发者平台申请获得的信息，没有的话不能工作
    paramsObject.apiKey = API_KEY;
    paramsObject.secretKey = SECRET_KEY;
    
    // 设置是否需要语义理解，只在搜索模式下有效果
    paramsObject.isNeedNLU = [ZCYBDYYConfig sharedInstance].isNeedNLU;
    
    // 设置识别语言
    paramsObject.language = [ZCYBDYYConfig sharedInstance].recognitionLanguage;
    
    // 设置识别模式，分为搜索和输入
    paramsObject.recogPropList = @[[ZCYBDYYConfig sharedInstance].recognitionProperty];
    
    // 设置城市ID，当时别属性包含EVoiceRecognitionPropertyMap时有效，1默认全国
    paramsObject.cityID = 1;
    
    // 开启联系人识别
//    paramsObject.enableContacts = YES;
    
    // 设置显示效果，是否开启连续上屏
    if ([ZCYBDYYConfig sharedInstance].resultContinuousShow) {
        paramsObject.resultShowMode = BDRecognizerResultShowModeContinuousShow;
    }
    else {
        paramsObject.resultShowMode = BDRecognizerResultShowModeWholeShow;
    }
    
    // 设置提示音开关，是否打开，默认打开
    if ([ZCYBDYYConfig sharedInstance].uiHintMusicSwitch) {
        paramsObject.recordPlayTones = EBDRecognizerPlayTonesRecordPlay;
    }
    else {
        paramsObject.recordPlayTones = EBDRecognizerPlayTonesRecordForbidden;
    }
    
    // 引擎启动后3秒没检测到语音，是否在动效下方随机出现一条提示语。如果配置了提示语列表，则默认开启
    paramsObject.isShowTipAfter3sSilence = NO;
    // 未检测到语音异常时，将“取消”按钮替换成帮助按钮。在配置了提示语列表后，默认开启
    paramsObject.isShowHelpButtonWhenSilence = NO;
//    paramsObject.tipsTitle = @"可是使用如下指令";
//    paramsObject.tipsList = [NSArray arrayWithObjects:@"我要记账", @"买苹果花了10块钱", @"买西瓜花了5块钱", "第四行以后滚动可见" , @"第五行是最后一行", nil];
    
    [_recognizerViewController startWithParams:paramsObject];
}

#pragma mark - 
#pragma mark ---------- clean ----------

- (void)clean
{
    _textViewStatusNotification.text = nil;
    _textViewRecogntionResult.text = nil;
}

#pragma mark - 
#pragma mark ---------- log & result ----------

- (void)logOutToContinusManualResult:(NSString *)result
{
    _textViewRecogntionResult.text = result;
}

- (void)logOutToManualResult:(NSString *)result
{
    NSString *string = _textViewRecogntionResult.text;
    if (string == nil || [string isEqualToString:@""]) {
        _textViewRecogntionResult.text = result;
    }
    else {
        _textViewRecogntionResult.text = [_textViewRecogntionResult.text stringByAppendingString:result];
    }
}

- (void)logOutToLogView:(NSString *)log
{
    NSString *string = _textViewStatusNotification.text;
    if (string == nil || [string isEqualToString:@""]) {
        _textViewStatusNotification.text = log;
    }
    else {
        _textViewStatusNotification.text = [_textViewStatusNotification.text stringByAppendingFormat:@"\r\n%@", log];
    }
}


@end
