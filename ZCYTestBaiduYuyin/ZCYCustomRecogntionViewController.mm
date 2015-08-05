//
//  ZCYCustomRecogntionViewController.m
//  ZCYTestBaiduYuyin
//
//  Created by zhaochunyang on 15/8/4.
//  Copyright (c) 2015年 zhaochunyang. All rights reserved.
//

#import "ZCYCustomRecogntionViewController.h"
#import "ZCYCustomUI.h"
#import "ZCYBDYYConfig.h"
#import "ZCYBDYYViewController.h"

/**
 *  音量监听频率 10次/秒
 */
#define  VOICE_LEVEL_INTERVAL 0.1

@interface ZCYCustomRecogntionViewController ()

- (void)createInitView; // 创建初始化界面，播放提示音会用到
- (void)createRecordView; // 创建录音界面
- (void)createRecognitionView; // 创建语音识别界面
- (void)createErrorViewWithErrorType:(int)status; // 在识别view中显示详细错误信息
- (void)createRunLogWithStatus:(int)status; // 在状态view中显示详细状态信息

- (void)finishRecord:(id)sender; // 用户点击完成动作
- (void)cancel:(id)sender; // 用户点击取消动作

- (void)startVoiceLevelMeterTimer;
- (void)freeVoiceLevelMeterTimer;

@end

@implementation ZCYCustomRecogntionViewController
@synthesize dialog = _dialog;
@synthesize clientViewController;
@synthesize voiceLevelMeterTimer = _voiceLevelMeterTimer;

#pragma mark - 
#pragma mark --------- view lifestyle ----------

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
    }
    return self;
}

- (void)dealloc
{
    [self freeVoiceLevelMeterTimer];
}

- (void)loadView
{
    UIView *customView = [[UIView alloc] initWithFrame:[[ZCYCustomUI sharedInstance] VRBackgroundFrame]];
    customView.backgroundColor = [UIColor clearColor];
    self.view = customView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 开始语音识别之前，必须实现MVoiceRecognitionClientDelegate协议中的VoiceRecognitionClientWorkStatus:obj方法
    int startStatus = -1;
    startStatus = [[BDVoiceRecognitionClient sharedInstance] startVoiceRecognition:self];
    
    //创建失败则报告错误
    if (startStatus != EVoiceRecognitionStartWorking) {
        NSString *statusString = [NSString stringWithFormat:@"%d", startStatus];
        [self performSelector:@selector(firstStartError:) withObject:statusString afterDelay:0.3]; // 延迟0.3秒，以便能再出错时正常删除view
        return;
    }
    
    // 是否需要播放开始说话提示音，如果是，则提示用户不要说话，在播放完成后在开始说话，也就是收到EVoiceRecognitionClientWorkStatusStartWorking通知后在开始说话。
    if ([ZCYBDYYConfig sharedInstance].playStartMusicSwitch) {
        [self createInitView];
    }
    else {
        [self createRecordView];
    }
    
    self.view.alpha = 0.0f;
    
    [UIView beginAnimations:@"show" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationDuration:0.3f];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    self.view.alpha = 1.f;
    [UIView commitAnimations];
}

- (void)didReceiveMemoryWarning
{
    [self cancel:nil];
    // 发生内存警告说时，停止语音识别，避免出现崩溃
    self.clientViewController.textViewStatusNotification.text = [self.clientViewController.textViewStatusNotification.text stringByAppendingFormat:@"\n内存警告，停止本次识别"];
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark ---------- button action methods ----------

- (void)finishRecord:(id)sender
{
    [[BDVoiceRecognitionClient sharedInstance] speakFinish];
}

- (void)cancel:(id)sender
{
    [[BDVoiceRecognitionClient sharedInstance] stopVoiceRecognition];
    
    if (self.view.superview) {
        [self.view removeFromSuperview];
    }
}

#pragma mark -
#pragma mark ---------- MVoiceRecognitonClient Delegate ----------

- (void)VoiceRecognitionClientErrorStatus:(int)aStatus subStatus:(int)aSubStatus
{
    // 为了更加具体显示错误信息，这里没有使用aStatus参数
    [self createErrorViewWithErrorType:aSubStatus];
}

- (void)VoiceRecognitionClientWorkStatus:(int)aStatus obj:(id)aObj
{
    switch (aStatus) {
        case EVoiceRecognitionClientWorkStatusFlushData: {// 连续上屏中间结果
            NSString *text = [aObj objectAtIndex:0];
            
            if ([text length] > 0) {
                [clientViewController logOutToContinusManualResult:text];
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusFinish: {// 识别正常并得到结果
            [self createRunLogWithStatus:aStatus];
            
            if ([[BDVoiceRecognitionClient sharedInstance] getRecognitionProperty] != EVoiceRecognitionPropertyInput) {
                // 搜索模式结果为数组，如：["公元", "公园"]
                NSMutableArray *audioResultData = (NSMutableArray *)aObj;
                NSMutableString *string = [[NSMutableString alloc] initWithString:@""];
                
                for (int i = 0; i < [audioResultData count]; i ++) {
                    [string appendFormat:@"%@\r\n", [audioResultData objectAtIndex:0]];
                }
                
                clientViewController.textViewRecogntionResult.text = nil;
                [clientViewController logOutToManualResult:string];
            }
            else {
                NSString *string = [[ZCYBDYYConfig sharedInstance] composeInputModeResult:aObj];
                [clientViewController logOutToContinusManualResult:string];
            }
            
            if (self.view.superview) {
                [self.view removeFromSuperview];
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusReceiveData: {
            
            // 此状态只有在输入模式下使用
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
            NSString *string = [[ZCYBDYYConfig sharedInstance] composeInputModeResult:aObj];
            [clientViewController logOutToContinusManualResult:string];
            break;
        }
        case EVoiceRecognitionClientWorkStatusEnd: { //  用户说完，等待服务器返回识别结果
            [self createRunLogWithStatus:aStatus];
            if ([ZCYBDYYConfig sharedInstance].voiceLevelMeter) {
                [self freeVoiceLevelMeterTimer];
            }
            [self createRecognitionView];
            break;
        }
        case EVoiceRecognitionClientWorkStatusCancel: {
            if ([ZCYBDYYConfig sharedInstance].voiceLevelMeter) {
                [self freeVoiceLevelMeterTimer];
            }
            [self createRunLogWithStatus:aStatus];
            if (self.view.superview) {
                [self.view removeFromSuperview];
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusStartWorkIng: {// 识别库开始识别工作，用户可以说话
            if ([ZCYBDYYConfig sharedInstance].playStartMusicSwitch) {// 如果播放了提示音，此时再给用户提示可以说话
                [self createRecordView];
            }
            if ([ZCYBDYYConfig sharedInstance].voiceLevelMeter) {// 开始音量监听
                [self startVoiceLevelMeterTimer];
            }
            [self createRunLogWithStatus:aStatus];
            break;
        }
        case EVoiceRecognitionClientWorkStatusNone:
        case EVoiceRecognitionClientWorkPlayStartTone:
        case EVoiceRecognitionClientWorkPlayStartToneFinish:
        case EVoiceRecognitionClientWorkStatusStart:
        case EVoiceRecognitionClientWorkPlayEndTone:
        case EVoiceRecognitionClientWorkPlayEndToneFinish: {
            [self createRunLogWithStatus:aStatus];
            break;
        }
        case EVoiceRecognitionClientWorkStatusNewRecordData: {
            break;
        }
        default: {
            [self createRunLogWithStatus:aStatus];
            if ([ZCYBDYYConfig sharedInstance].voiceLevelMeter) {
                [self freeVoiceLevelMeterTimer];
            }
            if (self.view.superview) {
                [self.view removeFromSuperview];
            }
            break;
        }
    }
}

- (void)VoiceRecognitionClientNetWorkStatus:(int)aStatus
{
    switch (aStatus) {
        case EVoiceRecognitionClientNetWorkStatusStart: {
            [self createRunLogWithStatus:aStatus];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            break;
        }
        case EVoiceRecognitionClientNetWorkStatusEnd: {
            [self createRunLogWithStatus:aStatus];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            break;
        }
        default:
            break;
    }
}

#pragma mark - 
#pragma mark ---------- voice search error result ----------

- (void)firstStartError:(NSString *)statusString
{
    if (self.view.superview) {
        [self.view removeFromSuperview];
    }
    [self createErrorViewWithErrorType:[statusString intValue]];
}

- (void)createErrorViewWithErrorType:(int)status
{
    NSString *errorMsg = @"";
    switch (status)
    {
        case EVoiceRecognitionClientErrorStatusIntrerruption:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonInterruptRecord", nil);
            break;
        }
        case EVoiceRecognitionClientErrorStatusChangeNotAvailable:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonChangeNotAvailable", nil);
            break;
        }
        case EVoiceRecognitionClientErrorStatusUnKnow:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonStatusError", nil);
            break;
        }
        case EVoiceRecognitionClientErrorStatusNoSpeech:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNoSpeech", nil);
            break;
        }
        case EVoiceRecognitionClientErrorStatusShort:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNoShort", nil);
            break;
        }
        case EVoiceRecognitionClientErrorStatusException:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonException", nil);
            break;
        }
        case EVoiceRecognitionClientErrorNetWorkStatusError:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNetWorkError", nil);
            break;
        }
        case EVoiceRecognitionClientErrorNetWorkStatusUnusable:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNoNetWork", nil);
            break;
        }
        case EVoiceRecognitionClientErrorNetWorkStatusTimeOut:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNetWorkTimeOut", nil);
            break;
        }
        case EVoiceRecognitionClientErrorNetWorkStatusParseError:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonParseError", nil);
            break;
        }
        case EVoiceRecognitionStartWorkNoAPIKEY:
        {
            errorMsg = NSLocalizedString(@"StringAudioSearchNoAPIKEY", nil);
            break;
        }
        case EVoiceRecognitionStartWorkGetAccessTokenFailed:
        {
            errorMsg = NSLocalizedString(@"StringAudioSearchGetTokenFailed", nil);
            break;
        }
        case EVoiceRecognitionStartWorkDelegateInvaild:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNoDelegateMethods", nil);
            break;
        }
        case EVoiceRecognitionStartWorkNetUnusable:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNoNetWork", nil);
            break;
        }
        case EVoiceRecognitionStartWorkRecorderUnusable:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonCantRecord", nil);
            break;
        }
        case EVoiceRecognitionStartWorkNOMicrophonePermission:
        {
            errorMsg = NSLocalizedString(@"StringAudioSearchNOMicrophonePermission", nil);
            break;
        }
            //服务器返回错误
        case EVoiceRecognitionClientErrorNetWorkStatusServerNoFindResult:     //没有找到匹配结果
        case EVoiceRecognitionClientErrorNetWorkStatusServerSpeechQualityProblem:    //声音过小
            
        case EVoiceRecognitionClientErrorNetWorkStatusServerParamError:       //协议参数错误
        case EVoiceRecognitionClientErrorNetWorkStatusServerRecognError:      //识别过程出错
        case EVoiceRecognitionClientErrorNetWorkStatusServerAppNameUnknownError: //appName验证错误
        case EVoiceRecognitionClientErrorNetWorkStatusServerUnknownError:      //未知错误
        {
            errorMsg = [NSString stringWithFormat:@"%@-%d",NSLocalizedString(@"StringVoiceRecognitonServerError", nil),status] ;
            break;
        }
        default:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonDefaultError", nil);
            break;
        }
    }
    
    [clientViewController logOutToManualResult:errorMsg];
}

#pragma mark - 
#pragma mark ---------- voice search views ----------

#pragma mark - voice search views

- (void)createInitView
{
    if (_dialog && _dialog.superview)
        [_dialog removeFromSuperview];
    
    UIImageView *tmpImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"recordBackground.png"]];
    tmpImageView.userInteractionEnabled = YES;
    tmpImageView.alpha = 0.6; /* He Liqiang, TAG-130729 */
    self.dialog = tmpImageView;
    _dialog.backgroundColor = [UIColor clearColor];
    _dialog.center = self.view.center;
    [self.view addSubview:_dialog];
    
    tmpImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"microphone.png"]];
    tmpImageView.center = [[ZCYCustomUI sharedInstance] VRRecordBackgroundCenter];
    [_dialog addSubview:tmpImageView];
    
    UILabel *tmpLabel = [[UILabel alloc] initWithFrame:[[ZCYCustomUI sharedInstance] VRRecordTintWordFrame]];
    tmpLabel.backgroundColor = [UIColor clearColor];
    tmpLabel.font = [UIFont boldSystemFontOfSize:28.0f];
    tmpLabel.textColor = [UIColor whiteColor];
    tmpLabel.text = NSLocalizedString(@"StringVoiceRecognitonInit", nil);
    tmpLabel.textAlignment = NSTextAlignmentCenter;
    tmpLabel.center = [[ZCYCustomUI sharedInstance] VRTintWordCenter];
    [_dialog addSubview:tmpLabel];
    
    UIButton *tmpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tmpButton.frame = [[ZCYCustomUI sharedInstance] VRCenterButtonFrame];
    tmpButton.center = [[ZCYCustomUI sharedInstance] VRCenterButtonCenter];
    tmpButton.backgroundColor = [UIColor clearColor];
    [tmpButton setTitle:NSLocalizedString(@"StringCancel", nil) forState:UIControlStateNormal];
    tmpButton.titleLabel.font = [UIFont boldSystemFontOfSize:20.0f];
    tmpButton.titleLabel.textColor = [UIColor whiteColor];
    [_dialog addSubview:tmpButton];
    [tmpButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    tmpButton.showsTouchWhenHighlighted = YES;
}

- (void)createRecordView
{
    if (_dialog && _dialog.superview)
        [_dialog removeFromSuperview];
    
    UIImageView *tmpImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"recordBackground.png"]];
    tmpImageView.userInteractionEnabled = YES;
    tmpImageView.alpha = 0.6; /* He Liqiang, TAG-130729 */
    self.dialog = tmpImageView;
    _dialog.backgroundColor = [UIColor clearColor];
    _dialog.center = self.view.center;
    [self.view addSubview:_dialog];
    
    tmpImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"microphone.png"]];
    tmpImageView.center = [[ZCYCustomUI sharedInstance] VRRecordBackgroundCenter];
    [_dialog addSubview:tmpImageView];
    
    UILabel *tmpLabel = [[UILabel alloc] initWithFrame:[[ZCYCustomUI sharedInstance] VRRecordTintWordFrame]];
    tmpLabel.backgroundColor = [UIColor clearColor];
    tmpLabel.font = [UIFont boldSystemFontOfSize:28.0f];
    tmpLabel.textColor = [UIColor whiteColor];
    tmpLabel.text = NSLocalizedString(@"StringVoiceRecognitonPleaseSpeak", nil);
    tmpLabel.textAlignment = NSTextAlignmentCenter;
    tmpLabel.center = [[ZCYCustomUI sharedInstance] VRTintWordCenter];
    [_dialog addSubview:tmpLabel];
    
    UIButton *tmpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tmpButton.frame = [[ZCYCustomUI sharedInstance] VRLeftButtonFrame];
    tmpButton.backgroundColor = [UIColor clearColor];
    [tmpButton setTitle:NSLocalizedString(@"StringCancel", nil) forState:UIControlStateNormal];
    tmpButton.titleLabel.font = [UIFont boldSystemFontOfSize:20.0f];
    tmpButton.titleLabel.textColor = [UIColor whiteColor];
    [_dialog addSubview:tmpButton];
    [tmpButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    tmpButton.showsTouchWhenHighlighted = YES;
    
    tmpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tmpButton.frame = [[ZCYCustomUI sharedInstance] VRRightButtonFrame];
    [tmpButton setTitle:NSLocalizedString(@"StringVoiceRecognitonRecordFinish", nil) forState:UIControlStateNormal];
    tmpButton.titleLabel.textColor = [UIColor whiteColor];
    tmpButton.titleLabel.font = [UIFont boldSystemFontOfSize:20.0f];
    [_dialog addSubview:tmpButton];
    [tmpButton addTarget:self action:@selector(finishRecord:) forControlEvents:UIControlEventTouchUpInside];
    tmpButton.showsTouchWhenHighlighted = YES;
    
}

- (void)createRecognitionView
{
    if (_dialog && _dialog.superview)
        [_dialog removeFromSuperview];
    
    UIImageView *tmpImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"recognitionBackground.png"]];
    tmpImageView.userInteractionEnabled = YES;
    tmpImageView.alpha = 0.6; /* He Liqiang, TAG-130729 */
    self.dialog = tmpImageView;
    _dialog.center = self.view.center;
    [self.view addSubview:_dialog];
    
    tmpImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"recognitionIcon.png"]];
    tmpImageView.center = [[ZCYCustomUI sharedInstance] VRRecognizeBackgroundCenter];
    [_dialog addSubview:tmpImageView];
    
    UILabel *tmpLabel = [[UILabel alloc] initWithFrame:[[ZCYCustomUI sharedInstance] VRRecognizeTintWordFrame]];
    tmpLabel.backgroundColor = [UIColor clearColor];
    tmpLabel.font = [UIFont boldSystemFontOfSize:28.0f];
    tmpLabel.textColor = [UIColor whiteColor];
    tmpLabel.text = NSLocalizedString(@"StringVoiceRecognitonIdentify", nil);
    tmpLabel.textAlignment = NSTextAlignmentCenter;
    tmpLabel.center = [[ZCYCustomUI sharedInstance] VRTintWordCenter];
    [_dialog addSubview:tmpLabel];
    
    UIButton *tmpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tmpButton.frame = [[ZCYCustomUI sharedInstance] VRCenterButtonFrame];
    tmpButton.center = [[ZCYCustomUI sharedInstance] VRCenterButtonCenter];
    tmpButton.backgroundColor = [UIColor clearColor];
    [tmpButton setTitle:NSLocalizedString(@"StringCancel", nil) forState:UIControlStateNormal];
    tmpButton.titleLabel.font = [UIFont boldSystemFontOfSize:20.0f];
    tmpButton.titleLabel.textColor = [UIColor whiteColor];
    [_dialog addSubview:tmpButton];
    [tmpButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    tmpButton.showsTouchWhenHighlighted = YES;
    
}

#pragma mark - voice search log

- (void)createRunLogWithStatus:(int)aStatus
{
    NSString *statusMsg = nil;
    switch (aStatus)
    {
        case EVoiceRecognitionClientWorkStatusNone: //空闲
        {
            statusMsg = NSLocalizedString(@"StringLogStatusNone", nil);
            break;
        }
        case EVoiceRecognitionClientWorkPlayStartTone:  //播放开始提示音
        {
            statusMsg = NSLocalizedString(@"StringLogStatusPlayStartTone", nil);
            break;
        }
        case EVoiceRecognitionClientWorkPlayStartToneFinish: //播放开始提示音完成
        {
            statusMsg = NSLocalizedString(@"StringLogStatusPlayStartToneFinish", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusStartWorkIng: //识别工作开始，开始采集及处理数据
        {
            statusMsg = NSLocalizedString(@"StringLogStatusStartWorkIng", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusStart: //检测到用户开始说话
        {
            statusMsg = NSLocalizedString(@"StringLogStatusStart", nil);
            break;
        }
        case EVoiceRecognitionClientWorkPlayEndTone: //播放结束提示音
        {
            statusMsg = NSLocalizedString(@"StringLogStatusPlayEndTone", nil);
            break;
        }
        case EVoiceRecognitionClientWorkPlayEndToneFinish: //播放结束提示音完成
        {
            statusMsg = NSLocalizedString(@"StringLogStatusPlayEndToneFinish", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusReceiveData: //语音识别功能完成，服务器返回正确结果
        {
            statusMsg = NSLocalizedString(@"StringLogStatusSentenceFinish", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusFinish: //语音识别功能完成，服务器返回正确结果
        {
            statusMsg = NSLocalizedString(@"StringLogStatusFinish", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusEnd: //本地声音采集结束结束，等待识别结果返回并结束录音
        {
            statusMsg = NSLocalizedString(@"StringLogStatusEnd", nil);
            break;
        }
        case EVoiceRecognitionClientNetWorkStatusStart: //网络开始工作
        {
            statusMsg = NSLocalizedString(@"StringLogStatusNetWorkStatusStart", nil);
            break;
        }
        case EVoiceRecognitionClientNetWorkStatusEnd:  //网络工作完成
        {
            statusMsg = NSLocalizedString(@"StringLogStatusNetWorkStatusEnd", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusCancel:  // 用户取消
        {
            statusMsg = NSLocalizedString(@"StringLogStatusNetWorkStatusCancel", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusError: // 出现错误
        {
            statusMsg = NSLocalizedString(@"StringLogStatusNetWorkStatusErorr", nil);
            break;
        }
        default:
        {
            statusMsg = NSLocalizedString(@"StringLogStatusNetWorkStatusDefaultErorr", nil);
            break;
        }
    }
    
    if (statusMsg)
    {
        NSString *logString = self.clientViewController.textViewStatusNotification.text;
        if (logString && [logString isEqualToString:@""] == NO)
        {
            self.clientViewController.textViewStatusNotification.text = [logString stringByAppendingFormat:@"\r\n%@", statusMsg];
        }
        else
        {
            self.clientViewController.textViewStatusNotification.text = statusMsg;
        }
    }
}

#pragma mark - VoiceLevelMeterTimer methods

- (void)startVoiceLevelMeterTimer
{
    [self freeVoiceLevelMeterTimer];
    
    NSDate *tmpDate = [[NSDate alloc] initWithTimeIntervalSinceNow:VOICE_LEVEL_INTERVAL];
    NSTimer *tmpTimer = [[NSTimer alloc] initWithFireDate:tmpDate interval:VOICE_LEVEL_INTERVAL target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    self.voiceLevelMeterTimer = tmpTimer;
    [[NSRunLoop currentRunLoop] addTimer:_voiceLevelMeterTimer forMode:NSDefaultRunLoopMode];
}

- (void)freeVoiceLevelMeterTimer
{
    if(_voiceLevelMeterTimer)
    {
        if([_voiceLevelMeterTimer isValid])
            [_voiceLevelMeterTimer invalidate];
        self.voiceLevelMeterTimer = nil;
    }
}

- (void)timerFired:(id)sender
{
    // 获取语音音量级别
    int voiceLevel = [[BDVoiceRecognitionClient sharedInstance] getCurrentDBLevelMeter];
    
    NSString *statusMsg = [NSLocalizedString(@"StringLogVoiceLevel", nil) stringByAppendingFormat:@": %d", voiceLevel];
    [clientViewController logOutToLogView:statusMsg];
}

#pragma mark - animation finish

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context 
{
    // 
}

@end
