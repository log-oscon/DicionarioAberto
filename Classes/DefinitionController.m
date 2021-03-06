//
//  DefinitionController.m
//  DicionarioAberto
//
//  Created by Luís Rodrigues on 21/12/2010.
//

#import "DefinitionController.h"
#import "SVProgressHUD.h"

@implementation DefinitionController

#pragma mark Instance Methods

- (id)initWithRequest:(NSString *)entry atIndex:(int)n {
    if (self == [super init]) {
        requestResults = nil;
        requestEntry = [entry copy];
        requestN = n;
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated {
}


// Additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Navigation bar
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(showInfoTable) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
        
    // Swipe gestures
    swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRightAction)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRight.delegate = self;
    [container addGestureRecognizer:swipeRight];
    
    swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeftAction)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeLeft.delegate = self;
    [container addGestureRecognizer:swipeLeft];

    swipeDoesNothing = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDoesNothingAction)];
    swipeDoesNothing.direction = UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown;
    swipeDoesNothing.delegate = self;
    [container addGestureRecognizer:swipeDoesNothing];
    
    definitionView1.delegate = self;
    definitionView2.delegate = self;
    
    pager.numberOfPages = 1;
    transitioning = NO;
    touchRequest = NO;
    
    [self searchDicionarioAberto:requestEntry];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}




// Generate HTML entry
- (NSString *)htmlEntryFrom:(NSArray *)entries atIndex:(int)n {
    
    NSString *entryOrth = nil;
    
    NSMutableString *content = [NSMutableString stringWithString:@""];
    
    // Header
    NSString *headerPath = [[NSBundle mainBundle] pathForResource:@"_def_header" ofType:@"html"];
    [content appendString:[NSString stringWithContentsOfFile:headerPath encoding:NSUTF8StringEncoding error:nil]];
    
    // Loop over definition entries
    for (Entry *entry in entries) {
        // Skip entry:
        if (n && entry.n && entry.n != n) {
            continue;
        }
        
        if (entryOrth == nil) {
            entryOrth = [DAParser markupToText:entry.entryForm.orth];
            self.title = [entryOrth lowercaseString];
        }
        
        [content appendString:@"<h1 class=\"term\">"];
        if (entries.count > 1) {
            [content appendFormat:@"<span class=\"index\">%d</span>", entry.n];
        }
        [content appendString:entryOrth];
        if ([entry.entryForm.phon length]) {
            [content appendFormat:@"<span class=\"phon\">, (%@)</span>", entry.entryForm.phon];
        }
        [content appendString:@"</h1>"];
        
        [content appendString:@"<section class=\"senses\">"];
        [content appendString:@"<section class=\"sense\">"];
        [content appendString:@"<ol class=\"definitions\">"];
        
        // Loop over definitions
        for (EntrySense *sense in entry.entrySense) {
            
            // Lexical category
            if (sense.gramGrp) {
                [content appendFormat:@"<div class=\"lex\">%@</div>", sense.gramGrp];
            }
            
            BOOL firstDef = YES;
            
            // Definitions
            for (NSString *chunk in [[DAParser markupToHTML:sense.def] componentsSeparatedByString: @"\n"]) {
                
                if (chunk.length > 0) {
                    if ([[chunk substringToIndex:1] isEqual:@"("]) {
                        [content appendFormat:@"<div class=\"note\">%@</div>", chunk];
                        
                    } else {
                        [content appendString:@"<li><span class=\"singledef\">"];
                        if (firstDef && sense.usg.text.length > 0) {
                            [content appendFormat:@"<span class=\"usage %@\">%@</span> ", sense.usg.type, sense.usg.text];
                            firstDef = NO;
                        }
                        [content appendString:chunk];
                        [content appendString:@"</span></li>"];
                    }
                }
            }
        }
        
        [content appendString:@"</ol>"];
        [content appendString:@"</section>"];
        
        // Etymology
        if (entry.entryEtymology.text) {
            [content appendString:@"<section class=\"etym\">"];
            [content appendString:[DAParser markupToHTML:entry.entryEtymology.text]];
            [content appendString:@"</section>"];
        }
        
        [content appendString:@"</section>"];
    }
    
    // Footer
    NSString *footerPath = [[NSBundle mainBundle] pathForResource:@"_def_footer" ofType:@"html"];
    NSMutableString *footer = [NSMutableString stringWithContentsOfFile:footerPath encoding:NSUTF8StringEncoding error:nil];
    
    footer = (NSMutableString *)[[NSRegularExpression regularExpressionWithPattern:@"%ENTRY%" options:0 error:nil] stringByReplacingMatchesInString:footer options:0 range:NSMakeRange(0, [footer length]) withTemplate:entryOrth];

    footer = (NSMutableString *)[[NSRegularExpression regularExpressionWithPattern:@"%FOOTER_CLASS%" options:0 error:nil] stringByReplacingMatchesInString:footer options:0 range:NSMakeRange(0, [footer length]) withTemplate:(n && [entries count] > 1) ? @"pager" : @""];
    
    [content appendString:footer];
              
    return content;
}


- (void)searchDicionarioAberto:(NSString *)query {
    // Obtain definition from DicionarioAberto API    
    
    [SVProgressHUD show];
    
    // Perform new asynchronous request
    [Entry entriesWithURLString:[NSString stringWithFormat:@"/search-xml/%@", [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                     parameters:nil
                        success:^(NSArray *records) {
                            [SVProgressHUD dismiss];
                            
                            requestResults = (NSMutableArray *)records;
                            
                            if (touchRequest) {
                                [self performTransitionTo:requestResults atIndex:requestN];
                            } else {
                                [self loadEntry:definitionView1 withArray:requestResults atIndex:requestN];
                            }

                        }
                        failure:^(NSError *error) {
                            [SVProgressHUD dismiss];
                            touchRequest = NO;
                            // TODO: Check error type
                            [self loadError:definitionView1 ofType:DARemoteSearchEmpty withString:query];
                            //[self loadError:definitionView1 ofType:DARemoteSearchUnavailable withString:query];
                            //[self loadError:definitionView1 ofType:DARemoteSearchNoConnection withString:query];
                            NSLog(@"%@", error);
                        }
     ];
}


- (void)loadError:(UIWebView *)wv ofType:(int)errorStatus withString:(NSString *)query {
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    NSString *path;
    
    if (errorStatus == DARemoteSearchNoConnection) {
        self.title = @"Erro de ligação";
        path = [[NSBundle mainBundle] pathForResource:@"error_connection" ofType:@"html"];
        
    } else if (errorStatus == DARemoteSearchEmpty) {
        self.title = @"Inexistente";
        path = [[NSBundle mainBundle] pathForResource:@"error_notfound" ofType:@"html"];
        
    } else {
        self.title = @"Indisponível";
        path = [[NSBundle mainBundle] pathForResource:@"error_unavailable" ofType:@"html"];
    }

    
    NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    [definitionView1 loadHTMLString:html baseURL:baseURL];
}


- (void)loadEntry:(UIWebView *)wv withArray:(NSArray *)entries atIndex:(int)n {
    if (entries != nil && [entries count] && n > 0) {
        pager.numberOfPages = [entries count];
        pager.currentPage = n - 1;
    } else {
        pager.numberOfPages = 1;
        pager.currentPage = 0;
    }
    
    if (entries != nil && [entries count]) {
        self.title = requestEntry;
        NSString *html = [self htmlEntryFrom:entries atIndex:n];
        NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        [wv loadHTMLString:html baseURL:baseURL];
        baseURL = nil;
        html = nil;
    } else {
        [self loadError:wv ofType:DARemoteSearchEmpty withString:@""];
    }
}


- (void)performTransitionTo:(NSArray *)results atIndex:(int)n {
    
    if (!touchRequest && n == requestN) {
        return;
    }
    
    BOOL transitionForward = NO;
    
    if (touchRequest && [requestEntry caseInsensitiveCompare:touchRequestPreviousEntry] == NSOrderedAscending) {
        transitionForward = YES;
    } else if (n < requestN) {
        transitionForward = YES;
    }
    
    CATransition *transition    = [CATransition animation];
    transition.duration         = 0.5;
    transition.timingFunction   = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type             = (transitionForward) ? kCATransitionMoveIn   : kCATransitionReveal;
    transition.subtype          = (transitionForward) ? kCATransitionFromLeft : kCATransitionFromRight;
    transition.delegate         = self;
    
    [container.layer addAnimation:transition forKey:nil];
    
    requestN = n;
    transitioning = YES;

    [self loadEntry:definitionView2 withArray:results atIndex:n];

    // Switch views only when definitionView2 finishes loading, see webViewDidFinishLoad
}


- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    transitioning = NO;
    touchRequest  = NO;
}


- (IBAction)changePage:(id)sender {
    if (!transitioning) {
        [self performTransitionTo:requestResults atIndex:(pager.currentPage + 1)];
    }
}


- (void)showInfoTable {
    InfoTableController *infoTable = [[InfoTableController alloc] init];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.title style:UIBarButtonItemStyleBordered target:nil action:nil];
    [self.navigationController pushViewController:infoTable animated:YES];
}

#pragma mark -
#pragma mark UIWebViewDelegate Methods

- (void)webViewDidStartLoad:(UIWebView *)webView {
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // Switch only when transitioning
    if (transitioning && webView == definitionView2) {
        definitionView1.hidden = YES;
        definitionView2.hidden = NO;
        
        UIWebView *tmp = definitionView2;
        definitionView2 = definitionView1;
        definitionView1 = tmp;
        
    } else if (webView == definitionView1) {
        definitionView1.hidden = NO;
    }
    
    definitionView1.userInteractionEnabled = YES;
    definitionView2.userInteractionEnabled = YES;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)urlRequest navigationType:(UIWebViewNavigationType)navigationType {
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSURL *url = [urlRequest URL];
        
        if ([[url scheme] isEqualToString:@"aberto"]) {
            // Internal links
            
            if ([[url host] isEqualToString:@"define"]) {
                touchRequest = YES;
                touchRequestPreviousEntry = [requestEntry copy];
                touchRequestPreviousN = requestN;
                
                // Definition links (aberto://define:*/*)
                requestEntry = [[url lastPathComponent] copy];
                requestN     = [[url port] integerValue];
                
                NSLog(@"Requested %@:%d", requestEntry, requestN);
                [self searchDicionarioAberto:requestEntry];
            }
            return NO;
            
        } else {
            [[UIApplication sharedApplication] openURL:url];
            return NO;
        }
    }
    
    return YES;
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}


- (void)swipeRightAction {
    if (!transitioning && requestN > 1) {
        definitionView1.userInteractionEnabled = NO;
        definitionView2.userInteractionEnabled = NO;
        [self performTransitionTo:requestResults atIndex:(requestN - 1)];
    }
}


- (void)swipeLeftAction {
    if (!transitioning && requestN > 0 && requestN < [requestResults count]) {
        definitionView1.userInteractionEnabled = NO;
        definitionView2.userInteractionEnabled = NO;
        [self performTransitionTo:requestResults atIndex:(requestN + 1)];
    }
}


- (void)swipeDoesNothingAction {
    // It really does nothing
}

@end
