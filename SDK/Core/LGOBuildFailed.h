//
//  LGOBuildFailed.h
//  LEGO-SDK-OC
//
//  Created by 崔明辉 on 16/7/26.
//  Copyright © 2016年 UED Center. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LGOProtocols.h"

@interface LGOBuildFailed : LGORequestable

@property(nonatomic, copy) NSString *error;
- (id)initWithErrorString:(NSString *)errorString;

@end

@interface LGOBuildFailedResponse : LGOResponse

@property(nonatomic, copy) NSString *error;
- (id)initWithErrorString:(NSString *)errorString;

@end