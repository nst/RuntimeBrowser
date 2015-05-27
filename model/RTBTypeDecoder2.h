//
//  RTBTypeDecoded2.h
//  runtime_cli
//
//  Created by Nicolas Seriot on 23/05/15.
//
//

#import <Foundation/Foundation.h>

//#include <objc/objc-api.h>

// http://opensource.apple.com/source/llvmgcc42/llvmgcc42-2336.9/libobjc/objc/objc-api.h
#define _C_ID       '@' // id
#define _C_CLASS    '#' // Class
#define _C_SEL      ':' // SEL
#define _C_CHR      'c' // char
#define _C_UCHR     'C' // unsigned char
#define _C_SHT      's' // short
#define _C_USHT     'S' // unsigned short
#define _C_INT      'i' // int
#define _C_UINT     'I' // unsigned int
#define _C_LNG      'l' // long
#define _C_ULNG     'L' // unsigned long
#define _C_LNG_LNG  'q' // long long
#define _C_ULNG_LNG 'Q' // unsigned long long
#define _C_FLT      'f' // float
#define _C_DBL      'd' // double
#define _C_BOOL	    'B' // bool (or _Bool)
#define _C_VOID     'v' // void
#define _C_CHARPTR  '*' // char*

#define _C_PTR      '^' // a pointer to some type is _C_PTR followed by the type string of the pointed-to type.
#define _C_BFLD     'b' // a bitfield in a structure is represented as _C_BFLD followed by an integer with the number of bits.
#define _C_ATOM     '%' //
#define _C_ARY_B    '[' // a C array is represented as _C_ARY_B followed by an integer representing the number of items followed by the encoded element type, followed by _C_ARY_E.
#define _C_ARY_E    ']' // ..
#define _C_UNION_B  '(' // a C union is represented as _C_UNION_B followed by the struct name, followed by '=', followed by the encoded types of all fields followed by _C_UNION_E. The field name (including the closing equals sign) is optional.
#define _C_UNION_E  ')' // ..
#define _C_STRUCT_B '{' // a C structure is represented as _C_STRUCT_B followed by the struct name, followed by '=', followed by the encoded types of all fields followed by _C_STRUCT_E. The field name (including the closing equals sign) is optional.#define _C_STRUCT_E '}'
#define _C_STRUCT_E '}' // ..
#define _C_VECTOR   '!'
#define _C_COMPLEX  'j'
// The C construct ‘const’ is mapped to _C_CONST, that is a const char* is represented as _C_CONST + _C_CHARPTR.

@interface RTBTypeDecoder2 : NSObject

@property (nonatomic, strong) NSDictionary *simpeTypesDictionary;

+ (NSArray *)decodeTypes:(NSString *)encodedType flat:(BOOL)flat;
+ (NSString *)decodeType:(NSString *)encodedType flat:(BOOL)flat;

- (NSDictionary *)decodeType:(NSString *)encodedType;
+ (NSInteger)indexOfClosingCharForString:(NSString *)s openingChar:(unichar)open closingChar:(unichar)close;
+ (NSString *)nameBeforeEqualInString:(NSString *)s;
+ (NSString *)descriptionForTypeDictionary:(NSDictionary *)d;

@end
