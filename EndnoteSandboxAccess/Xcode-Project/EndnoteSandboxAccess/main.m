//
//  main.m
//  EndnoteSandboxAccess
//
//  Created by hackerj on 08/02/16.
//  Copyright © 2016 ETHZ. All rights reserved.
//
/*
 based on infos from:
 http://objcolumnist.com/2012/05/21/security-scoped-file-url-bookmarks/

 compile ... and codesign (!):
 clang -framework Foundation -o EndnoteSandboxAccess main.m
 codesign --sign - EndnoteSandboxAccess
*/

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSError *error = nil;
        NSData *bookmarkData = nil;

        // path to be bookmarked as 'secure' -- bookmark target
        NSString *path = @"~/Library/Preferences/com.ThomsonResearchSoft.EndNote.plist";
        NSString *standardizedPath = [path stringByStandardizingPath];
        NSURL *prefsURL = [NSURL fileURLWithPath:standardizedPath];

        // file to save secure bookmark to
        NSString *outfile = @"~/Library/Containers/com.microsoft.Word/Data/Library/Preferences/com.ThomsonResearchSoft.EndNote.securebookmarks.plist";
        NSString *fullOutFile = [outfile stringByStandardizingPath];

        // File must exist to be bookmarkable...
        // This won't work if the word container doesn't exist yet.
        [[NSFileManager defaultManager] createFileAtPath:standardizedPath
                                                contents:nil
                                              attributes:nil];

        bookmarkData = [prefsURL
                        bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                        includingResourceValuesForKeys:nil
                        relativeToURL:nil
                        error:&error];

        if (error==NULL) {

          NSDictionary *bookmarkDict = @{ standardizedPath : bookmarkData };

          [bookmarkDict writeToFile:fullOutFile atomically:YES];

        } else {

          NSLog(@"%@", error);
          NSLog(@"Codesigning this binary fixes this yet-to-be-understood issue");

        }

    }
    return 0;
}
