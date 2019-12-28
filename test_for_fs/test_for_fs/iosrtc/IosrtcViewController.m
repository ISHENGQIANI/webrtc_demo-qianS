//
//  ViewController.m
//  webRTC
//
//  Created by qianS on 2019/11/2.
//  Copyright © 2019年 qianS. All rights reserved.
//

#import "IosrtcViewController.h"
#import "CallViewController.h"
#import "AFManager.h"

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

@interface IosrtcViewController () <UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate>

@property (strong, nonatomic) UITableView* friendsTableView;
@property (strong, nonatomic) UIButton* refreshBtn;
@property (strong, nonatomic) UIButton* leaveBtn;
@property (strong, nonatomic) UIButton* joinBtn;

@property (strong, nonatomic) NSMutableDictionary* friendsDic;
@property (strong, nonatomic) NSMutableArray* friendsArr;

@property (strong, nonatomic) AFManager* AFNet;

@property (strong, nonatomic) CallViewController* callView;

@end

@implementation IosrtcViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refresh];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.friendsDic = [NSMutableDictionary dictionary];
    [self refresh];
    
    self.AFNet = [[AFManager alloc] init];
    [self showUI];
}

- (void) refresh{
    //i should do GET with webSocket but not get friendsDic from local
    
    NSNumber* uuid = [[NSUserDefaults standardUserDefaults] valueForKey:@"id"];
    NSString* uid = [NSString stringWithFormat:@"%@", uuid];
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    
    [self.AFNet getContacts:uid group:group];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^(){
        bool isSuccess = [self.AFNet getIsSuccess];
        if (isSuccess == YES) {
            self.friendsDic = [[NSUserDefaults standardUserDefaults] valueForKey:@"friends"];
            NSLog(@"%@", self.friendsDic);
            if ([self.friendsDic isKindOfClass:[NSDictionary class]] && self.friendsDic.count != 0) {
                self.friendsArr = self.friendsDic.allKeys;
                NSLog(@"%@", self.friendsArr);
                [self.friendsTableView reloadData];
            }else{
                 [self showError:@"YOU HAVE NO FRIENDS!!!"];
                 [self leave];
            }
        }else{
            [self showError:@"please login first"];
        }
    });
}

- (void) showUI{
    CGFloat width = self.view.bounds.size.width;
    
    self.friendsTableView = [[UITableView alloc] initWithFrame:CGRectMake(20, 80, ScreenWidth-130, ScreenHeight-100) style:UITableViewStylePlain];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(myTableViewClick:)];
    [self.friendsTableView addGestureRecognizer:tapGesture];
    
    self.friendsTableView.delegate = self;
    self.friendsTableView.dataSource = self;
    [self.view addSubview:self.friendsTableView];
    
    self.refreshBtn = [[UIButton alloc] init];
    [self.refreshBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.refreshBtn setTintColor:[UIColor whiteColor]];
    [self.refreshBtn setTitle:@"Refresh" forState:UIControlStateNormal];
    [self.refreshBtn setBackgroundColor:[UIColor grayColor]];
    [self.refreshBtn setShowsTouchWhenHighlighted:YES];
    [self.refreshBtn setFrame:CGRectMake(width-100, 80, 80, 40)];
    [self.refreshBtn addTarget:self action:@selector(clickRefreshBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.refreshBtn];
    
    self.leaveBtn = [[UIButton alloc] init];
    [self.leaveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.leaveBtn setTintColor:[UIColor whiteColor]];
    [self.leaveBtn setTitle:@"Leave" forState:UIControlStateNormal];
    [self.leaveBtn setBackgroundColor:[UIColor grayColor]];
    [self.leaveBtn setShowsTouchWhenHighlighted:YES];
    [self.leaveBtn setFrame:CGRectMake(width-100, 130, 80, 40)];
    [self.leaveBtn addTarget:self action:@selector(clickLeaveBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.leaveBtn];
    
    self.joinBtn= [[UIButton alloc] init];
    [self.joinBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.joinBtn setTintColor:[UIColor whiteColor]];
    [self.joinBtn setTitle:@"join" forState:UIControlStateNormal];
    [self.joinBtn setBackgroundColor:[UIColor grayColor]];
    [self.joinBtn setShowsTouchWhenHighlighted:YES];
    [self.joinBtn setFrame:CGRectMake(width-100, 180, 80, 40)];
    [self.joinBtn addTarget:self action:@selector(clickJoinBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.joinBtn];
}

-(void)m_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"click table view!");
    //NSLog(@"client id = %@", self.friendsDic[self.friendsArr[indexPath.row]]);
    NSString* name = self.friendsArr[indexPath.row];
    NSNumber* uuid = [[NSUserDefaults standardUserDefaults] valueForKey:@"id"];
    NSNumber* ccid = self.friendsDic[self.friendsArr[indexPath.row]];
    NSString* uid = [NSString stringWithFormat:@"%@", uuid];
    NSString* cid = [NSString stringWithFormat:@"%@", ccid];
    
    UIAlertController *alertSheet = [UIAlertController alertControllerWithTitle:name message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* comfirmAction = [UIAlertAction actionWithTitle:@"语音通话" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        NSLog(@"click Call Action!");
        [self doCall:indexPath friendID:cid userID:uid];
    }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"click Cancel Action!");
    }];
    [alertSheet addAction:comfirmAction];
    [alertSheet addAction:cancelAction];
    [self presentViewController:alertSheet animated:YES completion:nil];
}

- (void)doCall:(NSIndexPath *)indexPath friendID:(NSString* )friendId userID:(NSString* )userId{
    NSLog(@"Do Call");
    [self.AFNet doCall:friendId];
    //[[NSUserDefaults standardUserDefaults] setObject:@false forKey:@"isCouldCall"];
    self.callView = [[CallViewController alloc] initWithId:friendId userID:userId];
    [self.callView.view setFrame:self.view.bounds];
    [self.callView.view setBackgroundColor:[UIColor whiteColor]];
    [self addChildViewController:self.callView];
    [self.callView didMoveToParentViewController:self];
    
    [self.view addSubview:self.callView.view];
}

- (void)showError:(NSString *)errorMsg {
    // 弹框提醒
    // 初始化对话框
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:errorMsg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    // 弹出对话框
    [self presentViewController:alert animated:true completion:nil];
}

- (void) clickLeaveBtn:(UIButton*) sender {
    
    NSLog(@"Leave GrantAdd View Controller!");
    [self leave];
}

- (void) clickJoinBtn:(UIButton*) sender {
    self.callView = [[CallViewController alloc] initWithId:@"2565" userID:@"2839"];
    [self.callView.view setFrame:self.view.bounds];
    [self.callView.view setBackgroundColor:[UIColor whiteColor]];
    
    [self addChildViewController:self.callView];
    [self.callView didMoveToParentViewController:self];
    
    [self.view addSubview:self.callView.view];
    NSLog(@"Leave GrantAdd View Controller!");
    [self leave];
}

- (void) leave{
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

- (void) clickRefreshBtn:(UIButton*) sender {
    NSLog(@"Click Refresh Button!");
    [self refresh];
}

#pragma mark - 点击事件
- (void)myTableViewClick:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self.friendsTableView];
    NSIndexPath *indexpath = [self.friendsTableView indexPathForRowAtPoint:point];
    if ([self respondsToSelector:@selector(m_tableView:didSelectRowAtIndexPath:)]) {
        [self m_tableView:self.friendsTableView didSelectRowAtIndexPath:indexpath];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.friendsArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *ide = @"Friends List";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ide];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ide];
    }
    cell.textLabel.text = [self.friendsArr objectAtIndex:indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end