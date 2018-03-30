//
//  Case8TableViewCell.m
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/16.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "Case8TableViewCell.h"
#import "Case8DataEntity.h"

@interface Case8TableViewCell()

@property (nonatomic, strong) UILabel* titleLabel;
@property (nonatomic, strong) UILabel* contentLabel;
@property (nonatomic, strong) UIButton* moreButton;

@property (nonatomic, strong) MASConstraint* heightConstraint;

@property (nonatomic, strong) Case8DataEntity* dataEntity;
@property (nonatomic, strong) NSIndexPath *indexPath;

@end

@implementation Case8TableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        [self initView];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    
}

- (void)dealloc
{
    [self removeKVO];
}

#pragma mark - UI Initialize

- (void)initView
{
    [self addKVO];
    
    _titleLabel = [UILabel new];
    [self.contentView addSubview:_titleLabel];
    
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.height.equalTo(@21);
        make.left.and.right.and.top.equalTo(self.contentView).with.insets(UIEdgeInsetsMake(4, 8, 4, 8));
    }];
    
    _moreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_moreButton setTitle:@"More" forState:UIControlStateNormal];
    [_moreButton addTarget:self action:@selector(swithExpandedState) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_moreButton];
    
    [_moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.height.equalTo(@32);
        make.left.and.right.and.bottom.equalTo(self.contentView);
    }];
    
    // Content
    // 计算UILabel的preferredMaxLayoutWidth值，多行时必须设置这个值，否则系统无法决定Label的宽度
    CGFloat preferredMaxWidth = [UIScreen mainScreen].bounds.size.width - 16;
    
    _contentLabel = [UILabel new];
    _contentLabel.numberOfLines = 0;
    _contentLabel.lineBreakMode = NSLineBreakByCharWrapping;
    _contentLabel.clipsToBounds = YES;
    _contentLabel.preferredMaxLayoutWidth = preferredMaxWidth;
    [self.contentView addSubview:_contentLabel];
    
    [_contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.and.right.equalTo(self.contentView).with.insets(UIEdgeInsetsMake(4, 8, 4, 8));
        make.top.equalTo(_titleLabel.mas_bottom).offset(4);
        make.bottom.equalTo(_moreButton.mas_top).offset(-4);
        // 高度约束优先级比required低一级
        _heightConstraint = make.height.equalTo(@64).with.priorityHigh();
    }];
}

#pragma mark - KVO

- (void)addKVO
{
    [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
}

- (void)removeKVO
{
    [self removeObserver:self forKeyPath:@"frame"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"frame"]) {
        
        NSValue *frameValue = change[NSKeyValueChangeOldKey];
        CGFloat oldHeight = [frameValue CGRectValue].size.height;
        
        frameValue = change[NSKeyValueChangeNewKey];
        CGFloat newHeight = [frameValue CGRectValue].size.height;
        
        NSLog(@"contentView: %p, height change from: %g, to: %g.", (__bridge void *) self.contentView, oldHeight, newHeight);
    }
}

#pragma mark - public method

- (void)setDataEntity:(id)entity indexPath:(NSIndexPath *)indexPath
{
    _dataEntity = entity;
    _indexPath = indexPath;
    _titleLabel.text = [NSString stringWithFormat:@"index: %ld, contentView: %p", (long) indexPath.row, (__bridge void *) self.contentView];
    _contentLabel.text = _dataEntity.content;
    
    // 这里决定是否使用label的固有高度size还是约束
    if (_dataEntity.expanded) [_heightConstraint uninstall];
    else [_heightConstraint install];
}

#pragma mark - private method

- (void)swithExpandedState
{
    if ([self.delegate respondsToSelector:@selector(case8Cell:switchExpandedStateWithIndexPath:)]) {
        
        [self.delegate case8Cell:self switchExpandedStateWithIndexPath:_indexPath];
    }
}

@end
