//
//  Case9ViewController.m
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/20.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

static const CGFloat ITEM_SIZE = 32;
static const NSUInteger ITEM_COUNT = 4;

#import "Case9ViewController.h"

@interface Case9ViewController ()

@property (weak, nonatomic) IBOutlet UIView *containerView1;
@property (weak, nonatomic) IBOutlet UIView *containerView2;
@property (weak, nonatomic) IBOutlet UIView *containerView3;
@property (weak, nonatomic) IBOutlet UISlider *sliderView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *container1WidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *container2WithConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *container3WidthConstraint;

@property (nonatomic, strong) NSArray* imageNames;
@property (nonatomic, assign) CGFloat maxWidth;

@end

@implementation Case9ViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self generateData];
    [self configSliderView];
    [self configContainerView1];
    [self configContainerView2];
    [self configContainer3];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - generate data

- (void)generateData
{
    _imageNames = @[@"bluefaces_1", @"bluefaces_2", @"bluefaces_3", @"bluefaces_4"];
    _maxWidth = _container1WidthConstraint.constant;
}

#pragma mark - UI

- (void)configSliderView
{
    _sliderView.maximumValue = _maxWidth;
    _sliderView.value = _maxWidth;
}

// 这个设置成间距被压缩
- (void)configContainerView1
{
    [_containerView1 setClipsToBounds:YES];
    UIView* lastSpaceView = [UIView new];
    lastSpaceView.backgroundColor = [UIColor greenColor];
    [_containerView1 addSubview:lastSpaceView];
    
    [lastSpaceView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.top.and.bottom.and.left.equalTo(_containerView1);
    }];
    
    for (int i = 0;i < ITEM_COUNT;i++) {
        
        UIImageView *imgView = [self getItemViewWithIndex:i];
        [_containerView1 addSubview:imgView];
        
        [imgView mas_makeConstraints:^(MASConstraintMaker *make) {
           
            make.width.and.height.equalTo(@(ITEM_SIZE)).with.priority(1000-i);
            make.left.equalTo(lastSpaceView.mas_right);
            make.centerY.equalTo(_containerView1.mas_centerY);
        }];
        
        UIView* spaceView = [UIView new];
        spaceView.backgroundColor = [UIColor greenColor];
        [_containerView1 addSubview:spaceView];
        
        [spaceView mas_makeConstraints:^(MASConstraintMaker *make) {
           
            make.left.equalTo(imgView.mas_right);
            make.top.and.bottom.equalTo(_containerView1);
            make.width.equalTo(lastSpaceView.mas_width);
        }];
        
        lastSpaceView = spaceView;
    }
    
    [lastSpaceView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_containerView1.mas_right);
    }];
}

// 这个设置成间距被压缩
- (void)configContainerView2
{
    [_containerView2 setClipsToBounds:YES];
    UIView* lastSpaceView = [UIView new];
    lastSpaceView.backgroundColor = [UIColor greenColor];
    [_containerView2 addSubview:lastSpaceView];
    
    [lastSpaceView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.and.bottom.and.left.equalTo(_containerView2);
    }];
    
    for (int i = 0;i < ITEM_COUNT;i++) {
        
        UIImageView *imgView = [self getItemViewWithIndex:i];
        [_containerView2 addSubview:imgView];
        
        [imgView mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.width.and.height.equalTo(@(ITEM_SIZE));
            make.left.equalTo(lastSpaceView.mas_right);
            make.centerY.equalTo(_containerView2.mas_centerY);
        }];
        
        UIView* spaceView = [UIView new];
        spaceView.backgroundColor = [UIColor greenColor];
        [_containerView2 addSubview:spaceView];
        
        [spaceView mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.left.equalTo(imgView.mas_right).with.priorityHigh();
            make.top.and.bottom.equalTo(_containerView2);
            make.width.equalTo(lastSpaceView.mas_width);
        }];
        
        lastSpaceView = spaceView;
    }
    
    [lastSpaceView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_containerView2.mas_right);
    }];
}

- (void)configContainer3
{
    for (int i = 0; i<ITEM_COUNT; i++) {
        
        UIImageView* imgView = [self getItemViewWithIndex:i];
        [_containerView3 addSubview:imgView];
        
        [imgView mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.width.and.height.equalTo(@(ITEM_SIZE));
            make.centerY.equalTo(_containerView3.mas_centerY);
//            make.centerX.equalTo(_containerView3.mas_right).multipliedBy(((CGFloat)i*2+1.f)/(CGFloat)(ITEM_COUNT*2));
            make.centerX.equalTo(_containerView3.mas_right).multipliedBy(((CGFloat)i + 1) / ((CGFloat)ITEM_COUNT + 1));
        }];
    }
}

#pragma mark - private method

- (UIImageView *)getItemViewWithIndex:(NSUInteger)index
{
    UIImage *image = [UIImage imageNamed:_imageNames[index % _imageNames.count]];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    return imageView;
}

#pragma mark - IBAction

- (IBAction)sliderValueChanged:(UISlider *)sender {
    
    _container1WidthConstraint.constant = sender.value;
    _container2WithConstraint.constant = sender.value;
    _container3WidthConstraint.constant = sender.value;
}

@end
