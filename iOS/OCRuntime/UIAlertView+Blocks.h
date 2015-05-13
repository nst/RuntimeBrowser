//
//  UIAlertView+Blocks.h
//  Shibui
//
//  Created by Jiva DeVoe on 12/28/10.
//  Copyright 2010 Random Ideas, LLC. All rights reserved.
//  Modified by Robert Saunders on 20/01/12
//

#import <Foundation/Foundation.h>

@interface UIAlertView (Blocks)


/* 
 
 This method only work if you want a one or two button alert view.  
 This should do for 90% of use cases, if you need more button use the standard constructor.
 
 For a one button alert provide nil for both the right button title and action
  
 This method will create and display the alert and automatically invoke the given block
  when the button is tapped.
 
 
 Example usage:

[UIAlertView displayAlertWithTitle:@"Example Alert View With Blocks"
                           message:@"What is the meaning of life?"
                   leftButtonTitle:@"41"
                  leftButtonAction:^{
                    NSLog(@"Incorrect");
                  } 
                  rightButtonTitle:@"42"
                 rightButtonAction:^{
                   [UIAlertView displayAlertWithTitle:@"Result"
                                              message:@"You chose wisely"
                                      leftButtonTitle:@"Ok"
                                     leftButtonAction:nil
                                     rightButtonTitle:nil
                                    rightButtonAction:nil];
                 }];
 
 
 */

+ (void)rtb_displayAlertWithTitle:(NSString *)title
                       message:(NSString *)message
               leftButtonTitle:(NSString *)leftButtonTitle
              leftButtonAction:(void (^)(void))leftButtonAction
              rightButtonTitle:(NSString*)rightButtonTitle
             rightButtonAction:(void (^)(NSString *output))rightButtonAction;



@end
