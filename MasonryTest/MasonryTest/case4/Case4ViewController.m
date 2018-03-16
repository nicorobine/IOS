//
//  Case4ViewController.m
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/15.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "Case4ViewController.h"
#import "Case4TableViewCell.h"
#import "Case4Model.h"

//#define IOS_8_NEW_FEATURE_SELF_SIZING

@interface Case4ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) Case4TableViewCell *tempCell;
@property (nonatomic, strong) NSMutableArray *datas;

@end

@implementation Case4ViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self generateDatas];
    [self configUI];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI

- (void)configUI {
    [_tableView registerClass:[Case4TableViewCell class] forCellReuseIdentifier:NSStringFromClass([Case4TableViewCell class])];
    _tableView.estimatedRowHeight = 80;
    
    if ([UIDevice currentDevice].systemVersion.integerValue > 7.0) {
//        _tableView.rowHeight = UITableViewAutomaticDimension;
    }
}

#pragma mark - Init datas

- (void)generateDatas
{
    if (!_datas) {
        _datas = [NSMutableArray new];
    }
    
    for (int i=0; i<20; i++) {
        Case4Model *model = [Case4Model new];
        model.title = [NSString stringWithFormat:@"title:%d", i];
        model.avatar = [UIImage imageNamed:[NSString stringWithFormat:@"bluefaces_%d", (i % 4) + 1]];
        model.content = [self getText:@"content-" withRepeat:i];
        
        [_datas addObject:model];
    }
}

// 重复text字符串repeat次
- (NSString *)getText:(NSString *)text withRepeat:(int)repeat {
    NSMutableString *tmpText = [NSMutableString new];
    
    for (int i = 0; i < repeat; i++) {
        [tmpText appendString:text];
    }
    
    return tmpText;
}


#pragma mark - UITableView delegate and datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Case4TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([Case4TableViewCell class]) forIndexPath:indexPath];
    
    Case4Model* model = [_datas objectAtIndex:indexPath.row];
    
    [cell setupData:model];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
#ifdef IOS_8_NEW_FEATURE_SELF_SIZING
    
    return UITableViewAutomaticDimension;
#endif
    
    CGFloat height = 0.f;
    Case4Model *entity = _datas[indexPath.row];
    
    // 如果没有计算好cell的高度，则计算
    if (entity.cellHeight<=0) {
        
        if (!_tempCell) {
            _tempCell = [Case4TableViewCell new];
        }
        
        [_tempCell setupData:entity];
        
        height = [_tempCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 0.5f;
        entity.cellHeight = height;
    } else {
        height = entity.cellHeight;
    }
    return height;
}

@end
