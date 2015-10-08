//  FSImageViewer
//
//  Created by Felix Schulze on 8/26/2013.
//  Copyright 2013 Felix Schulze. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <CommonCrypto/CommonDigest.h>
#import "FSImageLoader.h"

#import <SDWebImage/SDWebImageManager.h>

@implementation FSImageLoader {
    // Key = Url, value = id <SDWebImageOperation>)
    NSMutableDictionary *_runningImageOperations;
}

+ (FSImageLoader *)sharedInstance {
    static FSImageLoader *sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FSImageLoader alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _runningImageOperations = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (void)dealloc {
    [self cancelAllRequests];
}

- (void)cancelAllRequests {
    [[SDWebImageManager sharedManager] cancelAll];
}

- (void)cancelRequestForUrl:(NSURL *)aURL {
    NSString *urlAbsoluteString = aURL.absoluteString.lowercaseString;
    
    if (urlAbsoluteString != nil) {
        id <SDWebImageOperation> pendingImageRequest = [_runningImageOperations objectForKey:urlAbsoluteString];
        
        if (pendingImageRequest != nil) {
            [_runningImageOperations removeObjectForKey:urlAbsoluteString];
            
            [pendingImageRequest cancel];
            pendingImageRequest = nil;
        }
    }
}

- (void)loadImageForURL:(NSURL *)aURL progress:(void (^)(float progress))progress image:(void (^)(UIImage *image, NSError *error))imageBlock {
    
    [self cancelRequestForUrl:aURL]; // Cancel any existing image request if any!
    
    NSString *urlAbsoluteString = aURL.absoluteString;
    
    if (urlAbsoluteString != nil) {
        id <SDWebImageOperation> runningOperation = [[SDWebImageManager sharedManager].imageDownloader downloadImageWithURL:aURL options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            if (progress != nil) {
                progress( ((float)receivedSize) / ((float)expectedSize) );
            }
        } completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
            if (imageBlock != nil) {
                imageBlock(image, error);
            }
        }];
        
        [_runningImageOperations setObject:runningOperation forKey:urlAbsoluteString];
    }
    else {
        if (imageBlock != nil) {
            imageBlock(nil, [NSError errorWithDomain:@"FSImageLoaderErrorDomain" code:9999 userInfo:@{NSLocalizedDescriptionKey: @"URL is invalid!"}]);
        }
    }
}

@end