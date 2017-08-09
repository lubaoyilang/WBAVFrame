//
//  WBNativeRecorderFaceDetector.m
//  WBAVNAtiveRecorder
//
//  Created by 王博 on 2017/8/8.
//  Copyright © 2017年 王博. All rights reserved.
//

#import "WBNativeRecorderFaceDetector.h"

@interface WBNativeRecorderFaceDetector ()

@property (nonatomic, strong) CIContext *faceDetectorContext;

@property (nonatomic, strong) CIDetector *faceDetector;

@end

@implementation WBNativeRecorderFaceDetector

SingletonM(WBNativeRecorderFaceDetector)

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        self.faceDetectorContext = [CIContext contextWithEAGLContext:eaglContext];
        NSDictionary *faceDetectorDic = @{CIDetectorAccuracyHigh:CIDetectorAccuracy,
                                          @(YES):CIDetectorTracking,
                                          @(0.15):CIDetectorMinFeatureSize};
        self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:_faceDetectorContext options:faceDetectorDic];
      
    }
    
    return self;
}


+ (CIImage *)getNativeFaceDetectorRenderImageWithSmapleBuffer:(CMSampleBufferRef)sampleBuffer valueDic:(NSMutableDictionary *)dic
{
   
    CIDetector *faceDetector = [WBNativeRecorderFaceDetector sharedWBNativeRecorderFaceDetector].faceDetector;
    CVImageBufferRef imageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *faceDetectImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)imageBufferRef];
    
    //人脸检测
    NSArray *faceDetectResult = [faceDetector featuresInImage:faceDetectImage];
    CIImage *faceDetectedImage = faceDetectImage;
    
    //人脸检测标识
    for (CIFaceFeature *faceFeature in faceDetectResult)
    {
        //加快绘制性能，一次展开画板全部绘制进去
        UIImage *faceDrawImage = [[UIImage alloc] initWithCIImage:faceDetectedImage];
        NSLog(@"WB:%@", NSStringFromCGSize(faceDrawImage.size));
        
        
        //开启CG图形上下文，展开画板
        UIGraphicsBeginImageContextWithOptions(faceDrawImage.size, NO, [UIScreen mainScreen].scale);
        //将当前图像绘制在画板上
        [faceDrawImage drawInRect:CGRectMake(0, 0, faceDrawImage.size.width, faceDrawImage.size.height)];
        
        
        
        //绘制脸框
        //检测到的人脸的位置同opencv一样，需要以纵向中线为中心轴镜像对称一下
        UIBezierPath *facePath = [UIBezierPath bezierPathWithRect:CGRectMake(faceFeature.bounds.origin.x, faceFeature.bounds.origin.y, faceFeature.bounds.size.width,faceFeature.bounds.size.height)];
        facePath.lineWidth = 5.0;
        facePath.lineCapStyle = kCGLineCapRound;//线条拐角
        facePath.lineJoinStyle = kCGLineCapRound;//终点处理
        [[UIColor greenColor] set];//线条颜色处理
        [facePath stroke];
        
        //绘制左眼
        if (faceFeature.hasLeftEyePosition)
        {
            //检测到的人脸的位置同opencv一样，需要以纵向中线为中心轴镜像对称一下
            UIBezierPath *leftEyePath = [UIBezierPath bezierPathWithRect:CGRectMake(faceFeature.leftEyePosition.x, faceDrawImage.size.height-faceFeature.leftEyePosition.y, 50, 50)];
            leftEyePath.lineWidth = 5.0;
            leftEyePath.lineCapStyle = kCGLineCapRound;//线条拐角
            leftEyePath.lineJoinStyle = kCGLineCapRound;//终点处理
            [[UIColor greenColor] set];//线条颜色处理
            [leftEyePath stroke];
        }
        
        //绘制右眼
        if (faceFeature.hasRightEyePosition)
        {
            //检测到的人脸的位置同opencv一样，需要以纵向中线为中心轴镜像对称一下
            UIBezierPath *rightEyePath = [UIBezierPath bezierPathWithRect:CGRectMake(faceFeature.rightEyePosition.x, faceDrawImage.size.height-faceFeature.rightEyePosition.y, 50, 50)];
            rightEyePath.lineWidth = 5.0;
            rightEyePath.lineCapStyle = kCGLineCapRound;//线条拐角
            rightEyePath.lineJoinStyle = kCGLineCapRound;//终点处理
            [[UIColor greenColor] set];//线条颜色处理
            [rightEyePath stroke];
        }
        
        //绘制嘴巴
        if (faceFeature.hasMouthPosition)
        {
            //检测到的人脸的位置同opencv一样，需要以纵向中线为中心轴镜像对称一下
            UIBezierPath *mouthPath = [UIBezierPath bezierPathWithRect:CGRectMake(faceFeature.mouthPosition.x, faceDrawImage.size.height-faceFeature.mouthPosition.y, 100, 50)];
            mouthPath.lineWidth = 5.0;
            mouthPath.lineCapStyle = kCGLineCapRound;//线条拐角
            mouthPath.lineJoinStyle = kCGLineCapRound;//终点处理
            [[UIColor greenColor] set];//线条颜色处理
            [mouthPath stroke];
        }
        
        //检测微笑
        if (faceFeature.hasSmile)
        {
            NSLog(@"WBFACE: 你笑了,笑的那么美");
        }
        
        //检测左眼眨眼
        if (faceFeature.leftEyeClosed)
        {
            NSLog(@"WBFACE: 左眼眨眼了");
        }
        
        //检测右眼眨眼
        if (faceFeature.rightEyeClosed)
        {
            NSLog(@"WBFACE: 右眼眨眼了");
        }
        

        //渲染图像
        UIImage *faceRenderedImage = UIGraphicsGetImageFromCurrentImageContext();
        //关闭CG图形上下文
        UIGraphicsEndImageContext();
        CIImage *faceRenderedCIImage = [[CIImage alloc] initWithImage:faceRenderedImage];
        
        if (faceRenderedCIImage)
        {
            faceDetectedImage = faceRenderedCIImage;
        }
    }
    
    //渲染回frameBuffer
    CIContext *faceImageContext = [WBNativeRecorderFaceDetector sharedWBNativeRecorderFaceDetector].faceDetectorContext;
    [faceImageContext render:faceDetectedImage toCVPixelBuffer:imageBufferRef];
    
    return faceDetectedImage;
}

@end
