//
//  Case4TableViewCell.m
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/15.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "Case4TableViewCell.h"
#import "Case4Model.h"

@interface Case4TableViewCell ()

@property (nonatomic, strong) UIImageView* avatarView;
@property (nonatomic, strong) UILabel* titleLabel;
@property (nonatomic, strong) UILabel* contentLabel;

@property (nonatomic, strong) Case4Model* dataEntity;

@end

@implementation Case4TableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        [self initView];
    }
    
    return self;
}

- (void)setupData:(Case4Model *)dataEntity
{
    _avatarView.image = dataEntity.avatar;
    _titleLabel.text = dataEntity.title;
    _contentLabel.text = dataEntity.content;
    _dataEntity = dataEntity;
}

- (void)initView
{
    // 计算UILabel的preferredMaxLayoutWidth值，多行时必须设置这个值，否则系统无法决定Label的宽度
    CGFloat preferredMaxWidth = [UIScreen mainScreen].bounds.size.width - 44 - 4 * 3;
    
    _avatarView = [UIImageView new];
    _titleLabel = [UILabel new];
    _contentLabel = [UILabel new];
    _contentLabel.preferredMaxLayoutWidth = preferredMaxWidth;
    _contentLabel.numberOfLines = 0;
    
    [self.contentView addSubview:_avatarView];
    [self.contentView addSubview:_titleLabel];
    [self.contentView addSubview:_contentLabel];
    
    [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.width.and.height.equalTo(@44);
        make.left.and.top.equalTo(self.contentView).with.offset(4);
    }];
    
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.height.equalTo(@21);
        make.left.equalTo(_avatarView.mas_right).offset(4);
        make.top.equalTo(self.contentView).with.offset(4);
        make.right.equalTo(self.contentView).with.offset(-4);
    }];
    
    [_contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.equalTo(_avatarView.mas_right).with.offset(4);
        make.top.equalTo(_titleLabel.mas_bottom).with.offset(4);
        make.right.equalTo(self.contentView).with.offset(-4);
        make.bottom.equalTo(self.contentView).with.offset(-4);
    }];
    
    [_contentLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
}

@end
