//
//  Case8ViewController.m
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/16.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "Case8ViewController.h"
#import "Case8TableViewCell.h"
#import "Case8DataEntity.h"

@interface Case8ViewController () <UITableViewDelegate, UITableViewDataSource, Case8CellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) Case8TableViewCell *tempCell;

@property (nonatomic, strong) NSMutableArray *datas;

@end

@implementation Case8ViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self generateData];
    [self configUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

#pragma mark - config UI

- (void)configUI
{
    [_tableView registerClass:[Case8TableViewCell class] forCellReuseIdentifier:NSStringFromClass([Case8TableViewCell class])];
    _tableView.estimatedRowHeight = 80.f;
}

#pragma mark - Private methods

// 重复text字符串repeat次
- (NSString *)getText:(NSString *)text withRepeat:(int)repeat {
    NSMutableString *tmpText = [NSMutableString new];
    
    for (int i = 0; i < repeat; i++) {
        [tmpText appendString:text];
    }
    
    return tmpText;
}


// 生成数据
- (void)generateData {
    NSMutableArray *tmpData = [NSMutableArray new];
    
    for (int i = 0; i < 20; i++) {
        Case8DataEntity *dataEntity = [Case8DataEntity new];
        dataEntity.content = [self getText:@"case 8 content. " withRepeat:i * 2 + 10];
        [tmpData addObject:dataEntity];
    }
    
    _datas = tmpData;
}


#pragma mark - UITableView delegate and datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Case8TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([Case8TableViewCell class]) forIndexPath:indexPath];
    
    [cell setDataEntity:_datas[indexPath.row] indexPath:indexPath];
    cell.delegate = self;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_tempCell) {
        
        _tempCell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([Case8TableViewCell class])];
    }
    
    Case8DataEntity* entity = _datas[indexPath.row];
    
    if (entity.cellHeight <= 0) {
        
        [_tempCell setDataEntity:entity indexPath:indexPath];
        entity.cellHeight = [_tempCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 0.5f;
    }
    
    return entity.cellHeight;
}

#pragma mark - Case8CellDelegate

- (void)case8Cell:(Case8TableViewCell *)cell switchExpandedStateWithIndexPath:(NSIndexPath *)indexPath
{
    Case8DataEntity* entity = _datas[indexPath.row];
    entity.expanded = !entity.expanded;
    entity.cellHeight = 0;
    
    [_tableView beginUpdates];
    [_tableView endUpdates];
}

@end
