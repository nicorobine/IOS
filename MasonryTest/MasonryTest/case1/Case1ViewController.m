//
//  Case1ViewController.m
//  MasonryTest
//
//  Created by NicoRobine on 2018/3/15.
//  Copyright © 2018年 dreamdreamdream. All rights reserved.
//

#import "Case1ViewController.h"

@interface Case1ViewController ()

@property (nonatomic, strong) UILabel *label1;
@property (nonatomic, strong) UILabel *label2;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@end

@implementation Case1ViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self ConfigUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

#pragma mark - UI

- (void)ConfigUI {
    
    _label1 = [UILabel new];
    _label1.backgroundColor = [UIColor greenColor];
    _label1.text = @"label1";
    
    _label2 = [UILabel new];
    _label2.backgroundColor = [UIColor yellowColor];
    _label2.text = @"label2";
    
    [_contentView addSubview:_label1];
    [_contentView addSubview:_label2];
    
    [_label1 mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.equalTo(_contentView.mas_left).with.offset(5);
        make.top.equalTo(_contentView.mas_top).with.offset(2);
        
        make.height.equalTo(@40);
    }];
    
    [_label2 mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.equalTo(_label1.mas_right).with.offset(2);
        make.top.equalTo(_contentView.mas_top).with.offset(2);
        // 距离父视图右侧的距离大于等于2（由于mas使用-表示右侧的偏移量，所有<=-2）
        make.right.lessThanOrEqualTo(_contentView.mas_right).with.offset(-2);
        make.height.equalTo(@40);
        // 最小宽度为50
        make.width.greaterThanOrEqualTo(@50);
    }];
    
    [_label1 setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    // 设置抗压缩能力
    [_label1 setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    [_label2 setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    
    // 设置抗压缩能力
    [_label2 setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    
}


- (IBAction)stepperClicked:(UIStepper *)sender {
    
    switch (sender.tag) {
        case 0:
            _label1.text = [self getContentTextWithTag:sender.tag count:sender.value];
            break;
        case 1:
            _label2.text = [self getContentTextWithTag:sender.tag count:sender.value];
            break;
            
        default:
            break;
    }
    
}

// 根据根据数量获取text
- (NSString *)getContentTextWithTag:(NSUInteger)tag count:(NSUInteger)count
{
    NSMutableString *mulString = [NSMutableString new];
    for (int i = 0; i<count; i++) {
        
        if (tag) [mulString appendString:@"label2"];
        else [mulString appendString:@"label1"];
    }
    return mulString;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
