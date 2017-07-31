/*
 * Copyright 2010-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DDBDetailViewType) {
    DDBDetailViewTypeUnknown,
    DDBDetailViewTypeInsert,
    DDBDetailViewTypeUpdate
};

@class DDBTableRow;

@interface DDBDetailViewController : UIViewController

@property (nonatomic, assign) DDBDetailViewType viewType;
@property (nonatomic, strong) DDBTableRow *tableRow;

@property (nonatomic, weak) IBOutlet UITextField *hashKeyTextField;
@property (nonatomic, weak) IBOutlet UITextField *rangeKeyTextField;
@property (nonatomic, weak) IBOutlet UITextField *attribute1TextField;
@property (nonatomic, weak) IBOutlet UITextField *attribute2TextField;
@property (nonatomic, weak) IBOutlet UITextField *attribute3TextField;

- (IBAction)submit:(id)sender;

@end
