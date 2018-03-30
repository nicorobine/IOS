//
//  NBViewAnimationViewController.m
//  Animation
//
//  Created by NicoRobine on 2018/3/27.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//



#import "NBViewAnimationViewController.h"

static NSString *animation1 = @"animation1";

@interface NBViewAnimationViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UIView *demoView;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSArray *datas;

@end

@implementation NBViewAnimationViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self configUI];
}

#pragma mark - configUI

- (void)initUI
{
    [self.view addSubview:self.demoView];
    [self.view addSubview:self.collectionView];
}

- (void)configUI
{
    
    self.demoView.frame = CGRectMake((self.view.frame.size.width-80)/2, 100, 80, 80);
}

#pragma mark - UICollectionViewDatasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.datas.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([UICollectionViewCell class]) forIndexPath:indexPath];
    
    UILabel *contentLabel = [UILabel new];
    contentLabel.frame = CGRectMake(0, 0, 60, 21);
    contentLabel.text = _datas[indexPath.row];
    
    [cell.contentView addSubview:contentLabel];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < 5) {
        [self startAnimationWithIndex:indexPath.row];
    }
    else {
        [self startUIViewBlockAnimatoinWithIndex:indexPath.row];
    }
}

#pragma mark - Action Response

// UIView的基础动画
- (void)startAnimationWithIndex:(NSUInteger)index
{
    // 开始动画
    [UIView beginAnimations:animation1 context:nil];
    
    // 动画持续时间
    [UIView setAnimationDuration:2.f];
    
    // 动画代理(暂时还不知道怎么用)
    [UIView setAnimationDelegate:self];
    
    // 设置动画执行前执行的方法
    [UIView setAnimationWillStartSelector:@selector(willStartAnimation)];
    
    // 动画执行结束后的回调
    [UIView setAnimationDidStopSelector:@selector(didEndAnimation)];
    
    // 动画延时时间
    [UIView setAnimationDelay:0.f];
    
    // 动画重复次数(如果设置了AnimationRepeatAutoreverses为YES，则一个周期包含正反两个动画的持续时间)
    [UIView setAnimationRepeatCount:2.f];
    
    // 设置动画的曲线
    /*
     UIViewAnimationCurve的枚举值：
     UIViewAnimationCurveEaseInOut,         // 慢进慢出（默认值）
     UIViewAnimationCurveEaseIn,            // 慢进
     UIViewAnimationCurveEaseOut,           // 慢出
     UIViewAnimationCurveLinear             // 匀速
     */
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    // 是否从当前状态播放动画
    // @note 假设上一个动画正在播放，而且没有播放完毕，我们要执行一个新的动画
    // YES：动画从上一个动画所在的状态开始播放
    // NO：动画上一个动画指定的最终状态开始播放
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    // 设置动画是否继续执行相反的动画
    [UIView setAnimationRepeatAutoreverses:YES];
    
    // 是否禁用动画效果（动画的属性依然会改变只是没有动画效果）
    [UIView setAnimationsEnabled:YES];
    
    //设置视图的过渡效果
    /* 第一个参数：UIViewAnimationTransition的枚举值如下
     UIViewAnimationTransitionNone,              //不使用动画
     UIViewAnimationTransitionFlipFromLeft,      //从左向右旋转翻页
     UIViewAnimationTransitionFlipFromRight,     //从右向左旋转翻页
     UIViewAnimationTransitionCurlUp,            //从下往上卷曲翻页
     UIViewAnimationTransitionCurlDown,          //从上往下卷曲翻页
     第二个参数：需要过渡效果的View
     第三个参数：是否使用视图缓存，YES：视图在开始和结束时渲染一次；NO：视图在每一帧都渲染*/
//    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.demoView cache:YES];
    
    switch (index) {
        case 0:
        {
            self.demoView.transform = CGAffineTransformMakeRotation(M_PI);
            break;
        }
        case 1:
        {
            self.demoView.transform = CGAffineTransformMakeScale(2.f, 2.f);
            break;
        }
        case 2:
        {
            [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.demoView cache:YES];
            break;
        }
        case 3:
        {
            self.demoView.transform = CGAffineTransformMakeTranslation(100.f, 300.f);
            break;
        }
        case 4:
        {
            [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self.demoView cache:YES];
            break;
        }
            
        default:
            break;
    }
    
    // 结束动画
    [UIView commitAnimations];
}

// UIView使用block的动画
- (void)startUIViewBlockAnimatoinWithIndex:(NSUInteger)index
{
    __weak typeof(self) weakSelf = self;
    
    switch (index) {
        case 5:
        {
            
            [UIView animateWithDuration:0.1 delay:0.f options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionCurveEaseInOut animations:^{
                
                [UIView setAnimationRepeatCount:5.5];
                weakSelf.demoView.transform = CGAffineTransformMakeRotation(M_PI_4/6);
                weakSelf.demoView.transform = CGAffineTransformMakeRotation(-M_PI_4/6);
                
            } completion:^(BOOL finished) {
                weakSelf.demoView.transform = CGAffineTransformIdentity;
            }];
            
            break;
        }
        case 6:
        {
            [UIView animateWithDuration:2.f delay:0.5 usingSpringWithDamping:0.1 initialSpringVelocity:20 options:UIViewAnimationOptionCurveLinear animations:^{
                
                weakSelf.demoView.transform = CGAffineTransformMakeTranslation(100, 200);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:2.f delay:0.5 usingSpringWithDamping:0.1 initialSpringVelocity:20 options:UIViewAnimationOptionCurveLinear animations:^{
                    
                    weakSelf.demoView.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished) {
                    weakSelf.demoView.transform = CGAffineTransformIdentity;
                }];
            }];
            
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - private

- (void)willStartAnimation
{
    NSLog(@"Animation will start...");
}

- (void)didEndAnimation
{
    NSLog(@"Animation did end!");
    
    // 如果这里不把仿射转换置为空的话会出现组合变换的情况（会和前边的仿射变换叠加）
    self.demoView.transform = CGAffineTransformIdentity;
}

#pragma mark - getter

- (UIView *)demoView
{
    if (!_demoView) {
        
        _demoView = [UIView new];
        self.demoView.backgroundColor = [UIColor greenColor];
    }
    return _demoView;
}

- (NSArray *)datas
{
    if (!_datas) {
        
        _datas = @[@"旋转", @"缩放", @"翻转", @"平移", @"翻页", @"抖动b", @"精灵b"];
    }
    
    return _datas;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(20, 220, self.view.frame.size.width-40, 300) collectionViewLayout:[UICollectionViewFlowLayout new]];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([UICollectionViewCell class])];
    }
    
    return _collectionView;
}

@end
