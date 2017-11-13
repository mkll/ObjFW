/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "config.h"

#include <stdlib.h>
#include <string.h>

#import "OFURL.h"
#import "OFURL+Private.h"
#import "OFArray.h"
#import "OFNumber.h"
#import "OFString.h"
#import "OFXMLElement.h"

#ifdef OF_HAVE_FILES
# import "OFFileManager.h"
# import "OFURLHandler_file.h"
#endif

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"

static OFCharacterSet *URLAllowedCharacterSet = nil;
static OFCharacterSet *URLPathAllowedCharacterSet = nil;
static OFCharacterSet *URLQueryOrFragmentAllowedCharacterSet = nil;

@interface OFCharacterSet_URLAllowed: OFCharacterSet
+ (OFCharacterSet *)URLAllowedCharacterSet;
@end

@interface OFCharacterSet_URLPathAllowed: OFCharacterSet
+ (OFCharacterSet *)URLPathAllowedCharacterSet;
@end

@interface OFCharacterSet_URLQueryOrFragmentAllowed: OFCharacterSet
+ (OFCharacterSet *)URLQueryOrFragmentAllowedCharacterSet;
@end

@implementation OFCharacterSet_URLAllowed
+ (void)initialize
{
	if (self != [OFCharacterSet_URLAllowed class])
		return;

	URLAllowedCharacterSet = [[OFCharacterSet_URLAllowed alloc] init];
}

+ (OFCharacterSet *)URLAllowedCharacterSet
{
	return URLAllowedCharacterSet;
}

- (instancetype)autorelease
{
	return self;
}

- (instancetype)retain
{
	return self;
}

- (void)release
{
}

- (unsigned int)retainCount
{
	return OF_RETAIN_COUNT_MAX;
}

- (bool)characterIsMember: (of_unichar_t)character
{
	if (character < CHAR_MAX && of_ascii_isalnum(character))
		return true;

	switch (character) {
	case '-':
	case '.':
	case '_':
	case '~':
	case '!':
	case '$':
	case '&':
	case '\'':
	case '(':
	case ')':
	case '*':
	case '+':
	case ',':
	case ';':
	case '=':
		return true;
	default:
		return false;
	}
}
@end

@implementation OFCharacterSet_URLPathAllowed
+ (void)initialize
{
	if (self != [OFCharacterSet_URLPathAllowed class])
		return;

	URLPathAllowedCharacterSet =
	    [[OFCharacterSet_URLPathAllowed alloc] init];
}

+ (OFCharacterSet *)URLPathAllowedCharacterSet
{
	return URLPathAllowedCharacterSet;
}

- (instancetype)autorelease
{
	return self;
}

- (instancetype)retain
{
	return self;
}

- (void)release
{
}

- (unsigned int)retainCount
{
	return OF_RETAIN_COUNT_MAX;
}

- (bool)characterIsMember: (of_unichar_t)character
{
	if (character < CHAR_MAX && of_ascii_isalnum(character))
		return true;

	switch (character) {
	case '-':
	case '.':
	case '_':
	case '~':
	case '!':
	case '$':
	case '&':
	case '\'':
	case '(':
	case ')':
	case '*':
	case '+':
	case ',':
	case ';':
	case '=':
	case ':':
	case '@':
	case '/':
		return true;
	default:
		return false;
	}
}
@end

@implementation OFCharacterSet_URLQueryOrFragmentAllowed
+ (void)initialize
{
	if (self != [OFCharacterSet_URLQueryOrFragmentAllowed class])
		return;

	URLQueryOrFragmentAllowedCharacterSet =
	    [[OFCharacterSet_URLQueryOrFragmentAllowed alloc] init];
}

+ (OFCharacterSet *)URLQueryOrFragmentAllowedCharacterSet
{
	return URLQueryOrFragmentAllowedCharacterSet;
}

- (instancetype)autorelease
{
	return self;
}

- (instancetype)retain
{
	return self;
}

- (void)release
{
}

- (unsigned int)retainCount
{
	return OF_RETAIN_COUNT_MAX;
}

- (bool)characterIsMember: (of_unichar_t)character
{
	if (character < CHAR_MAX && of_ascii_isalnum(character))
		return true;

	switch (character) {
	case '-':
	case '.':
	case '_':
	case '~':
	case '!':
	case '$':
	case '&':
	case '\'':
	case '(':
	case ')':
	case '*':
	case '+':
	case ',':
	case ';':
	case '=':
	case ':':
	case '@':
	case '/':
	case '?':
		return true;
	default:
		return false;
	}
}
@end

@implementation OFCharacterSet (URLCharacterSets)
+ (OFCharacterSet *)URLSchemeAllowedCharacterSet
{
	return [OFCharacterSet_URLAllowed URLAllowedCharacterSet];
}

+ (OFCharacterSet *)URLHostAllowedCharacterSet
{
	return [OFCharacterSet_URLAllowed URLAllowedCharacterSet];
}

+ (OFCharacterSet *)URLUserAllowedCharacterSet
{
	return [OFCharacterSet_URLAllowed URLAllowedCharacterSet];
}

+ (OFCharacterSet *)URLPasswordAllowedCharacterSet
{
	return [OFCharacterSet_URLAllowed URLAllowedCharacterSet];
}

+ (OFCharacterSet *)URLPathAllowedCharacterSet
{
	return [OFCharacterSet_URLPathAllowed URLPathAllowedCharacterSet];
}

+ (OFCharacterSet *)URLQueryAllowedCharacterSet
{
	return [OFCharacterSet_URLQueryOrFragmentAllowed
	    URLQueryOrFragmentAllowedCharacterSet];
}

+ (OFCharacterSet *)URLFragmentAllowedCharacterSet
{
	return [OFCharacterSet_URLQueryOrFragmentAllowed
	    URLQueryOrFragmentAllowedCharacterSet];
}
@end

@implementation OFURL
+ (instancetype)URL
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)URLWithString: (OFString *)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

+ (instancetype)URLWithString: (OFString *)string
		relativeToURL: (OFURL *)URL
{
	return [[[self alloc] initWithString: string
			       relativeToURL: URL] autorelease];
}

#ifdef OF_HAVE_FILES
+ (instancetype)fileURLWithPath: (OFString *)path
{
	return [[[self alloc] initFileURLWithPath: path] autorelease];
}

+ (instancetype)fileURLWithPath: (OFString *)path
		    isDirectory: (bool)isDirectory
{
	return [[[self alloc] initFileURLWithPath: path
				      isDirectory: isDirectory] autorelease];
}
#endif

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_init
{
	return [super init];
}

- (instancetype)initWithString: (OFString *)string
{
	char *UTF8String, *UTF8String2 = NULL;

	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		char *tmp, *tmp2;

		if ((UTF8String2 = of_strdup([string UTF8String])) == NULL)
			@throw [OFOutOfMemoryException
			     exceptionWithRequestedSize:
			     [string UTF8StringLength]];

		UTF8String = UTF8String2;

		if ((tmp = strchr(UTF8String, ':')) == NULL)
			@throw [OFInvalidFormatException exception];

		if (strncmp(tmp, "://", 3) != 0)
			@throw [OFInvalidFormatException exception];

		for (tmp2 = UTF8String; tmp2 < tmp; tmp2++)
			*tmp2 = of_ascii_tolower(*tmp2);

		_URLEncodedScheme = [[OFString alloc]
		    initWithUTF8String: UTF8String
				length: tmp - UTF8String];

		UTF8String = tmp + 3;

		if ((tmp = strchr(UTF8String, '/')) != NULL) {
			*tmp = '\0';
			tmp++;
		}

		if ((tmp2 = strchr(UTF8String, '@')) != NULL) {
			char *tmp3;

			*tmp2 = '\0';
			tmp2++;

			if ((tmp3 = strchr(UTF8String, ':')) != NULL) {
				*tmp3 = '\0';
				tmp3++;

				_URLEncodedUser = [[OFString alloc]
				    initWithUTF8String: UTF8String];
				_URLEncodedPassword = [[OFString alloc]
				    initWithUTF8String: tmp3];
			} else
				_URLEncodedUser = [[OFString alloc]
				    initWithUTF8String: UTF8String];

			UTF8String = tmp2;
		}

		if ((tmp2 = strchr(UTF8String, ':')) != NULL) {
			OFString *portString;

			*tmp2 = '\0';
			tmp2++;

			_URLEncodedHost = [[OFString alloc]
			    initWithUTF8String: UTF8String];

			portString = [OFString stringWithUTF8String: tmp2];

			if ([portString decimalValue] > 65535)
				@throw [OFInvalidFormatException exception];

			_port = [[OFNumber alloc] initWithUInt16:
			    (uint16_t)[portString decimalValue]];
		} else
			_URLEncodedHost = [[OFString alloc]
			    initWithUTF8String: UTF8String];

		if ((UTF8String = tmp) != NULL) {
			if ((tmp = strchr(UTF8String, '#')) != NULL) {
				*tmp = '\0';

				_URLEncodedFragment = [[OFString alloc]
				    initWithUTF8String: tmp + 1];
			}

			if ((tmp = strchr(UTF8String, '?')) != NULL) {
				*tmp = '\0';

				_URLEncodedQuery = [[OFString alloc]
				    initWithUTF8String: tmp + 1];
			}

			UTF8String--;
			*UTF8String = '/';

			_URLEncodedPath = [[OFString alloc]
			    initWithUTF8String: UTF8String];
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	} @finally {
		free(UTF8String2);
	}

	return self;
}

- (instancetype)initWithString: (OFString *)string
		 relativeToURL: (OFURL *)URL
{
	char *UTF8String, *UTF8String2 = NULL;

	if ([string containsString: @"://"])
		return [self initWithString: string];

	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		char *tmp;

		_URLEncodedScheme = [URL->_URLEncodedScheme copy];
		_URLEncodedHost = [URL->_URLEncodedHost copy];
		_port = [URL->_port copy];
		_URLEncodedUser = [URL->_URLEncodedUser copy];
		_URLEncodedPassword = [URL->_URLEncodedPassword copy];

		if ((UTF8String2 = of_strdup([string UTF8String])) == NULL)
			@throw [OFOutOfMemoryException
			     exceptionWithRequestedSize:
			     [string UTF8StringLength]];

		UTF8String = UTF8String2;

		if ((tmp = strchr(UTF8String, '#')) != NULL) {
			*tmp = '\0';
			_URLEncodedFragment = [[OFString alloc]
			    initWithUTF8String: tmp + 1];
		}

		if ((tmp = strchr(UTF8String, '?')) != NULL) {
			*tmp = '\0';
			_URLEncodedQuery = [[OFString alloc]
			    initWithUTF8String: tmp + 1];
		}

		if (*UTF8String == '/')
			_URLEncodedPath = [[OFString alloc]
			    initWithUTF8String: UTF8String];
		else {
			OFString *path, *s;

			path = [OFString stringWithUTF8String: UTF8String];

			if ([URL->_URLEncodedPath hasSuffix: @"/"])
				s = [URL->_URLEncodedPath
				    stringByAppendingString: path];
			else
				s = [OFString stringWithFormat:
				    @"%@/../%@", URL->_URLEncodedPath, path];

			_URLEncodedPath =
			    [[s stringByStandardizingURLPath] copy];
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	} @finally {
		free(UTF8String2);
	}

	return self;
}

#ifdef OF_HAVE_FILES
- (instancetype)initFileURLWithPath: (OFString *)path
{
	@try {
		void *pool = objc_autoreleasePoolPush();
		bool isDirectory;

		isDirectory = ([path hasSuffix: OF_PATH_DELIMITER_STRING] ||
		    [OFURLHandler_file of_directoryExistsAtPath: path]);
		self = [self initFileURLWithPath: path
				     isDirectory: isDirectory];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initFileURLWithPath: (OFString *)path
			isDirectory: (bool)isDirectory
{
	@try {
		void *pool = objc_autoreleasePoolPush();
# if OF_PATH_DELIMITER != '/' || defined(OF_WINDOWS) || defined(OF_DJGPP)
		OFArray OF_GENERIC(OFString *) *pathComponents =
		    [path pathComponents];
# endif
		OFURL *currentDirectoryURL;

# if OF_PATH_DELIMITER != '/'
		path = [pathComponents componentsJoinedByString: @"/"];
# endif

# if defined(OF_WINDOWS) || defined(OF_DJGPP)
		if ([[pathComponents firstObject] hasSuffix: @":"])
			path = [path stringByPrependingString: @"/"];
# endif

		if (isDirectory && ![path hasSuffix: OF_PATH_DELIMITER_STRING])
			path = [path stringByAppendingString: @"/"];

		currentDirectoryURL =
		    [[OFFileManager defaultManager] currentDirectoryURL];

		self = [self initWithString: path
			      relativeToURL: currentDirectoryURL];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	@try {
		void *pool = objc_autoreleasePoolPush();

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		self = [self initWithString: [element stringValue]];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_URLEncodedScheme release];
	[_URLEncodedHost release];
	[_port release];
	[_URLEncodedUser release];
	[_URLEncodedPassword release];
	[_URLEncodedPath release];
	[_URLEncodedQuery release];
	[_URLEncodedFragment release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFURL *URL;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFURL class]])
		return false;

	URL = object;

	if (URL->_URLEncodedScheme != _URLEncodedScheme &&
	    ![URL->_URLEncodedScheme isEqual: _URLEncodedScheme])
		return false;
	if (URL->_URLEncodedHost != _URLEncodedHost &&
	    ![URL->_URLEncodedHost isEqual: _URLEncodedHost])
		return false;
	if (URL->_port != _port && ![URL->_port isEqual: _port])
		return false;
	if (URL->_URLEncodedUser != _URLEncodedUser &&
	    ![URL->_URLEncodedUser isEqual: _URLEncodedUser])
		return false;
	if (URL->_URLEncodedPassword != _URLEncodedPassword &&
	    ![URL->_URLEncodedPassword isEqual: _URLEncodedPassword])
		return false;
	if (URL->_URLEncodedPath != _URLEncodedPath &&
	    ![URL->_URLEncodedPath isEqual: _URLEncodedPath])
		return false;
	if (URL->_URLEncodedQuery != _URLEncodedQuery &&
	    ![URL->_URLEncodedQuery isEqual: _URLEncodedQuery])
		return false;
	if (URL->_URLEncodedFragment != _URLEncodedFragment &&
	    ![URL->_URLEncodedFragment isEqual: _URLEncodedFragment])
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, [_URLEncodedScheme hash]);
	OF_HASH_ADD_HASH(hash, [_URLEncodedHost hash]);
	OF_HASH_ADD_HASH(hash, [_port hash]);
	OF_HASH_ADD_HASH(hash, [_URLEncodedUser hash]);
	OF_HASH_ADD_HASH(hash, [_URLEncodedPassword hash]);
	OF_HASH_ADD_HASH(hash, [_URLEncodedPath hash]);
	OF_HASH_ADD_HASH(hash, [_URLEncodedQuery hash]);
	OF_HASH_ADD_HASH(hash, [_URLEncodedFragment hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString *)scheme
{
	return [_URLEncodedScheme stringByURLDecoding];
}

- (OFString *)URLEncodedScheme
{
	return _URLEncodedScheme;
}

- (OFString *)host
{
	return [_URLEncodedHost stringByURLDecoding];
}

- (OFString *)URLEncodedHost
{
	return _URLEncodedHost;
}

- (OFNumber *)port
{
	return _port;
}

- (OFString *)user
{
	return [_URLEncodedUser stringByURLDecoding];
}

- (OFString *)URLEncodedUser
{
	return _URLEncodedUser;
}

- (OFString *)password
{
	return [_URLEncodedPassword stringByURLDecoding];
}

- (OFString *)URLEncodedPassword
{
	return _URLEncodedPassword;
}

- (OFString *)path
{
	return [_URLEncodedPath stringByURLDecoding];
}

- (OFString *)URLEncodedPath
{
	return _URLEncodedPath;
}

- (OFArray *)pathComponents
{
	return [[self path] componentsSeparatedByString: @"/"];
}

- (OFString *)lastPathComponent
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path = [self path];
	const char *UTF8String, *lastComponent;
	size_t length;
	OFString *ret;

	if (path == nil) {
		objc_autoreleasePoolPop(pool);

		return nil;
	}

	if ([path isEqual: @"/"]) {
		objc_autoreleasePoolPop(pool);

		return @"";
	}

	if ([path hasSuffix: @"/"])
		path = [path substringWithRange:
		    of_range(0, [path length] - 1)];

	UTF8String = lastComponent = [path UTF8String];
	length = [path UTF8StringLength];

	for (size_t i = 1; i <= length; i++) {
		if (UTF8String[length - i] == '/') {
			lastComponent = UTF8String + (length - i) + 1;
			break;
		}
	}

	ret = [[OFString alloc]
	    initWithUTF8String: lastComponent
			length: length - (lastComponent - UTF8String)];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)query
{
	return [_URLEncodedQuery stringByURLDecoding];
}

- (OFString *)URLEncodedQuery
{
	return _URLEncodedQuery;
}

- (OFString *)fragment
{
	return [_URLEncodedFragment stringByURLDecoding];
}

- (OFString *)URLEncodedFragment
{
	return _URLEncodedFragment;
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	OFMutableURL *copy = [[OFMutableURL alloc] init];

	@try {
		[copy setURLEncodedScheme: _URLEncodedScheme];
		[copy setURLEncodedHost: _URLEncodedHost];
		[copy setPort: _port];
		[copy setURLEncodedUser: _URLEncodedUser];
		[copy setURLEncodedPassword: _URLEncodedPassword];
		[copy setURLEncodedPath: _URLEncodedPath];
		[copy setURLEncodedQuery: _URLEncodedQuery];
		[copy setURLEncodedFragment: _URLEncodedFragment];
	} @catch (id e) {
		[copy release];
		@throw e;
	}

	return copy;
}

- (OFString *)string
{
	OFMutableString *ret = [OFMutableString string];

	[ret appendFormat: @"%@://", _URLEncodedScheme];

	if (_URLEncodedUser != nil && _URLEncodedPassword != nil)
		[ret appendFormat: @"%@:%@@",
				   _URLEncodedUser, _URLEncodedPassword];
	else if (_URLEncodedUser != nil)
		[ret appendFormat: @"%@@", _URLEncodedUser];

	if (_URLEncodedHost != nil)
		[ret appendString: _URLEncodedHost];
	if (_port != nil)
		[ret appendFormat: @":%@", _port];

	if (_URLEncodedPath != nil) {
		if (![_URLEncodedPath hasPrefix: @"/"])
			@throw [OFInvalidFormatException exception];

		[ret appendString: _URLEncodedPath];
	}

	if (_URLEncodedQuery != nil)
		[ret appendFormat: @"?%@", _URLEncodedQuery];

	if (_URLEncodedFragment != nil)
		[ret appendFormat: @"#%@", _URLEncodedFragment];

	[ret makeImmutable];

	return ret;
}

- (OFString *)fileSystemRepresentation
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path;

	if (![_URLEncodedScheme isEqual: @"file"])
		@throw [OFInvalidArgumentException exception];

	if (![_URLEncodedPath hasPrefix: @"/"])
		@throw [OFInvalidFormatException exception];

	path = [self path];

	if ([path hasSuffix: @"/"])
		path = [path substringWithRange:
		    of_range(0, [path length] - 1)];

#ifndef OF_PATH_STARTS_WITH_SLASH
	path = [path substringWithRange: of_range(1, [path length] - 1)];
#endif

#if OF_PATH_DELIMITER != '/'
	path = [OFString pathWithComponents:
	    [path componentsSeparatedByString: @"/"]];
#endif

	[path retain];

	objc_autoreleasePoolPop(pool);

	return [path autorelease];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>",
					   [self class], [self string]];
}

- (OFXMLElement *)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: [self className]
				      namespace: OF_SERIALIZATION_NS
				    stringValue: [self string]];

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}
@end
