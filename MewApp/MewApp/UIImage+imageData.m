//
//  UIImage+imageData.m
//  XXTPickerCollection
//
//  Created by Zheng on 03/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "UIImage+imageData.h"

struct data_header_o {
    uint32_t hLen;
    uint32_t width;
    uint32_t height;
    uint32_t bytesPerRow;
    uint32_t bitsPerComponent;
    uint32_t colorDepth;
    uint32_t bitmapInfo;
    uint32_t arg7; // 0
}; // Just guess...

@implementation UIImage (imageData)

+ (UIImage *)imageWithImageData:(NSData *)imageData {
    
    struct data_header_o header;
    [imageData getBytes:&header range:NSMakeRange(0, 32)];
    if (header.hLen != 32)
    {
        [imageData getBytes:&header range:NSMakeRange(4, 32)];
    }
    if (header.hLen != 32)
    {
        return nil;
    }
    
    size_t bufSize = header.width * header.height * sizeof(uint32_t);
    uint32_t *pixels = (uint32_t *)malloc(bufSize);
    [imageData getBytes:pixels range:NSMakeRange(header.hLen, bufSize)];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(pixels, header.width, header.height, header.bitsPerComponent, header.bytesPerRow, colorSpace, header.bitmapInfo);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    UIImage *icon = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    free(pixels);
    return icon;
    
}

@end
