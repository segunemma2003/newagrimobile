#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "LaunchImage" asset catalog image resource.
static NSString * const ACImageNameLaunchImage AC_SWIFT_PRIVATE = @"LaunchImage";

/// The "icon" asset catalog image resource.
static NSString * const ACImageNameIcon AC_SWIFT_PRIVATE = @"icon";

#undef AC_SWIFT_PRIVATE
