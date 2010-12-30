//
//  DicionarioAbertoAppDelegate.h
//  DicionarioAberto
//
//  Created by Luís Rodrigues on 20/12/2010.
//

#import <UIKit/UIKit.h>

@class RootController;

@interface DADelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    RootController *viewController;
    UINavigationController *navController;
    
    NSArray *searchResults;
    NSArray *savedSearchResults;
    NSString *savedSearchText;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet RootController *viewController;
@property (nonatomic, retain) IBOutlet UINavigationController *navController;
@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, retain) NSArray *savedSearchResults;
@property (nonatomic, retain) NSString *savedSearchText;

- (void) searchDicionarioAberto:(NSString *)query;

@end

