//
//  MessageTableViewController.m
//  NFCDemo
//
//  Created by 轻舔指尖 on 2017/7/11.
//  Copyright © 2017年 youplus. All rights reserved.
//

#import "MessageTableViewController.h"
#import <CoreNFC/CoreNFC.h>

@interface MessageTableViewController ()<NFCNDEFReaderSessionDelegate, NFCReaderSessionDelegate>

@property (strong, nonatomic) NFCNDEFReaderSession *session;
@property (strong, nonatomic) NSMutableArray *dataAry;

@end

@implementation MessageTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"读取列表";
    
    self.dataAry = [[NSMutableArray alloc] init];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [btn setFrame:CGRectMake(0, 0, 44, 44)];
    [btn addTarget:self action:@selector(clickRightBtn) forControlEvents:UIControlEventTouchUpInside];
     self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
}

- (void)showAlertMsg:(NSString *)msg title:(NSString *)title
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:^{
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

- (void)clickRightBtn
{
    [self.session invalidateSession];
    self.session = [[NFCNDEFReaderSession alloc] initWithDelegate:self
                                                            queue:nil
                                         invalidateAfterFirstRead:NO];
    if (NFCNDEFReaderSession.readingAvailable) {
        self.session.alertMessage = @"把TAG放到手机背面";
        [self.session beginSession];
    } else {
        [self showAlertMsg:@"此设备不支持NFC" title:@""];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NFCReaderSessionDelegate
- (void)readerSessionDidBecomeActive:(NFCReaderSession *)session
{
    NSLog(@"NFC会话已激活");
    if (session.isReady) {
        NSLog(@"NFC已准备好");
    } else {
        [self showAlertMsg:@"NFC还没有准备好" title:@""];
    }
}

- (void)readerSession:(NFCReaderSession *)session
        didDetectTags:(NSArray<__kindof id<NFCTag>> *)tags
{
    NSLog(@"扫描到TAG数据");
}

#pragma mark - NFCNDEFReaderSessionDelegate

- (void)readerSession:(NFCNDEFReaderSession *)session didInvalidateWithError:(NSError *)error
{
    // 读取失败
    NSLog(@"%@",error);
    if (error.code == 201) {
        NSLog(@"扫描超时");
        [self showAlertMsg:error.userInfo[NSLocalizedDescriptionKey] title:@"扫描超时"];
    }
    
    if (error.code == 200) {
        NSLog(@"取消扫描");
        [self showAlertMsg:error.userInfo[NSLocalizedDescriptionKey] title:@"取消扫描"];
    }
}

- (void)readerSession:(NFCNDEFReaderSession *)session didDetectNDEFs:(NSArray<NFCNDEFMessage *> *)messages
{
    // 读取成功
    for (NFCNDEFMessage *msg in messages) {
        
        NSArray *ary = msg.records;
        for (NFCNDEFPayload *rec in ary) {
            
            NFCTypeNameFormat typeName = rec.typeNameFormat;
            NSData *payload = rec.payload;
            NSData *type = rec.type;
            NSData *identifier = rec.identifier;
            
            NSLog(@"TypeName : %d",typeName);
            NSLog(@"Payload : %@",payload);
            NSLog(@"Type : %@",type);
            NSLog(@"Identifier : %@",identifier);
        }
    }
    
    [self.dataAry addObject:messages];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataAry.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *)self.dataAry[section]).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"%lu 个 Message", (unsigned long)((NSArray *)self.dataAry[section]).count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    NFCNDEFMessage *tag = self.dataAry[indexPath.section][indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%lu Records", tag.records.count];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
