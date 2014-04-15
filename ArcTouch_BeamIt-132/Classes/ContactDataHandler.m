#import "ContactDataHandler.h"
#import "ContactDataProvider.h"

@implementation ContactDataHandler

- (NSObject<DataProvider> *)createDataProvider {
	return [[ContactDataProvider alloc] init];
}

@end
