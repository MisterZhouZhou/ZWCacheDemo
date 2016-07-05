

#import <Foundation/Foundation.h>


@interface NSString (Common)
- (NSString *)md5;
- (NSString *)md5Str;

- (CGSize)sizeForFont:(UIFont *)font size:(CGSize)size mode:(NSLineBreakMode)lineBreakMode;

- (CGFloat)widthForFont:(UIFont *)font;

- (CGFloat)heightForFont:(UIFont *)font width:(CGFloat)width;

@end
