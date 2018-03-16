//
//  Case7ViewController.m
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/16.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "Case7ViewController.h"

static CGFloat ParallaxHeaderHeight = 235;

@interface Case7ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIImageView* headerView;
@property (nonatomic, strong) MASConstraint* heightConstraint;

@property (nonatomic, strong) NSArray *datas;

@end

@implementation Case7ViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self generateData];
    [self configUI];
    [self addKVO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    
}

- (void)dealloc
{
    [_tableView removeObserver:self forKeyPath:@"contentOffset"];
}

#pragma mark - generateData

- (void)generateData
{
    _datas = @[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"11",@"12",@"13",@"14",@"15",@"16",@"17",];
}

#pragma mark - UI

- (void)configUI
{
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.contentInset = UIEdgeInsetsMake(ParallaxHeaderHeight, 0, 0, 0);
    _tableView.backgroundColor = [UIColor clearColor];
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
    
    _headerView = [UIImageView new];
    _headerView.image = [UIImage imageNamed:@"parallax_header_back"];
    _headerView.contentMode = UIViewContentModeScaleAspectFill;
    
    [self.view insertSubview:_headerView belowSubview:_tableView];
    
    [_headerView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.and.right.equalTo(_tableView);
        make.top.equalTo(self.mas_topLayoutGuideBottom);
        _heightConstraint = make.height.equalTo(@(ParallaxHeaderHeight));
    }];
}

#pragma mark - KVO

- (void)addKVO
{
    [_tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        
        CGPoint contentOffset = ((NSValue *)change[NSKeyValueChangeNewKey]).CGPointValue;
        
        _heightConstraint.equalTo(@(-contentOffset.y));
    }
}

#pragma mark - UITableView datasource and delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class]) forIndexPath:indexPath];
    
    cell.textLabel.text = _datas[indexPath.row];
    
    return cell;
}

@end
