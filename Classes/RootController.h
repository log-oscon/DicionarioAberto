//
//  DicionarioAbertoViewController.h
//  DicionarioAberto
//
//  Created by Luís Rodrigues on 20/12/2010.
//

#import "SearchCell.h"
#import "DefinitionController.h"
#import "InfoTableController.h"

#import "DADelegate.h"
#import "DARemote.h"
#import "DAParser.h"

#import "Entry.h"

@interface RootController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, DARemoteDelegate> {
    DADelegate *delegate;
    
    UITableView *searchResultsTable;
    DARemote *connection;
    
    BOOL searchPrefix;
    BOOL searching;
    BOOL letUserSelectRow;
    BOOL tableHasShadow;

    int searchStatus;
}

@property (nonatomic, retain) IBOutlet UITableView *searchResultsTable;

- (void)dropShadowFor:(UITableView *)tableView;
- (void)searchDicionarioAberto:(NSString *)query;
- (void)reloadSearchResultsTable:(UITableView *)tableView;
- (void)showInfoTable;
- (void)keyboardDidHide:(NSNotification *)notification;

@end

