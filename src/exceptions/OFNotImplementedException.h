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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFNotImplementedException \
 *	  OFNotImplementedException.h ObjFW/OFNotImplementedException.h
 *
 * @brief An exception indicating that a method or part of it is not
 *        implemented.
 */
@interface OFNotImplementedException: OFException
{
	SEL _selector;
	id _object;
}

/*!
 * The selector which is not or not fully implemented.
 */
@property (readonly) SEL selector;

/*!
 * The object which does not (fully) implement the selector.
 */
@property (readonly, nonatomic) id object;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased not implemented exception.
 *
 * @param selector The selector which is not or not fully implemented
 * @param object The object which does not (fully) implement the selector
 * @return A new, autoreleased not implemented exception
 */
+ (instancetype)exceptionWithSelector: (SEL)selector
			       object: (id)object;

- init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated not implemented exception.
 *
 * @param selector The selector which is not or not fully implemented
 * @param object The object which does not (fully) implement the selector
 * @return An initialized not implemented exception
 */
- initWithSelector: (SEL)selector
	    object: (id)object;
@end

OF_ASSUME_NONNULL_END
