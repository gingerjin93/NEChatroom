//
//  NTESMoreCell.m
//  NEChatroom-iOS-ObjC
//
//  Created by Wenchao Ding on 2021/1/27.
//  Copyright © 2021 netease. All rights reserved.
//

#import "NTESMoreCell.h"

@interface NTESMoreCell ()

@property (nonatomic, strong) CALayer *selectionLayer;

@end

@implementation NTESMoreCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.selectionLayer = [[CALayer alloc] init];
        self.selectionLayer.backgroundColor = [UIColor colorWithRed:242/255.0 green:243/255.0 blue:245/255.0 alpha:1.0].CGColor;
        self.selectionLayer.hidden = YES;
        [self.contentView.layer addSublayer:self.selectionLayer];
        
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.imageView.clipsToBounds = YES;
        self.imageView.layer.cornerRadius = 30;
        self.imageView.contentMode = UIViewContentModeCenter;
        self.imageView.backgroundColor = [UIColor colorWithRed:242/255.0 green:243/255.0 blue:245/255.0 alpha:1.0];
        [self.contentView addSubview:self.imageView];
        
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.textLabel.font = [UIFont systemFontOfSize:12];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.textLabel];
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.selectionLayer.frame = self.contentView.bounds;
    self.imageView.frame = CGRectMake(self.contentView.bounds.size.width/2.0-30, 0, 60, 60);
    self.textLabel.frame = CGRectMake(0, CGRectGetMaxY(self.imageView.frame) + 6, self.contentView.bounds.size.width, 18);
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.selectionLayer.hidden = !highlighted;
}

@end
