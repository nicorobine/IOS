//
//  Case8TableViewCell.h
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/16.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Case8DataEntity;
@class Case8TableViewCell;

@protocol Case8CellDelegate <NSObject>

- (void)case8Cell:(Case8TableViewCell *)cell switchExpandedStateWithIndexPath:(NSIndexPath *)indexPath;

@end

@interface Case8TableViewCell : UITableViewCell

@property (nonatomic, assign) id <Case8CellDelegate> delegate;

- (void)setDataEntity:(Case8DataEntity *)entity indexPath:(NSIndexPath *)indexPath;

@end
