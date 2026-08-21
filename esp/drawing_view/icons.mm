#import "icons.h"
#import <UIKit/UIKit.h>

UIImage* FloatButtonIcon(void) {
    // Bạn có thể tăng kích thước này để logo to hơn nữa
    CGFloat buttonSize = 34.0f;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(buttonSize, buttonSize), NO, [UIScreen mainScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextSetShouldAntialias(ctx, YES);
    CGContextSetAllowsAntialiasing(ctx, YES);

    // ✅ ĐÃ XÓA NỀN ĐEN – KHÔNG VẼ HÌNH TRÒN NỀN

    // Load ảnh icon.png (nên để ảnh trong suốt để trông đẹp)
    UIImage *img = [UIImage imageNamed:@"icon.png"];
    if (img) {
        // Cắt theo hình tròn (nếu ảnh có nền trong suốt thì phần ngoài sẽ trong suốt)
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, buttonSize, buttonSize)];
        [path addClip];
        // Vẽ ảnh full kích thước (to nhất có thể)
        [img drawInRect:CGRectMake(0, 0, buttonSize, buttonSize)];
    } else {
        // Fallback nếu không có ảnh – vẽ chữ "M" to hơn
        NSDictionary *attrs = @{
            NSFontAttributeName: [UIFont boldSystemFontOfSize:20],
            NSForegroundColorAttributeName: [UIColor whiteColor]
        };
        [@"M" drawInRect:CGRectMake(7, 5, 20, 24) withAttributes:attrs];
    }

    UIImage *finalIcon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return finalIcon;
}