/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */


#import "CKSingleChildComponent.h"

#import "CKBuildComponent.h"
#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKTreeNode.h"

@implementation CKSingleChildComponent
{
  CKComponent *_childComponent;
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
{
  // As we are going to retrieve the state from the `CKBaseTreeNode`
  // We don't need to acuire the scope handle from 'CKThreadLocalComponentScope::currentScope'.
  return [super newWithViewWithoutAcquiringScopeHandle:view size:size];
}

- (CKComponent *)render:(id)state
{
  return nil;
}

- (void)buildComponentTree:(CKTreeNode *)owner
             previousOwner:(CKTreeNode *)previousOwner
                 scopeRoot:(CKComponentScopeRoot *)scopeRoot
              stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{
  auto const isOwnerComponent = [[self class] isOwnerComponent];
  const Class nodeClass = isOwnerComponent ? [CKTreeNode class] : [CKBaseTreeNode class];
  CKBaseTreeNode *const node = [[nodeClass alloc]
                                initWithComponent:self
                                owner:owner
                                previousOwner:previousOwner
                                scopeRoot:scopeRoot
                                stateUpdates:stateUpdates];

  auto const child = [self render:node.state];
  if (child) {
    _childComponent = child;
    [child buildComponentTree:(isOwnerComponent ? (CKTreeNode *)node : owner)
                previousOwner:(isOwnerComponent ? (CKTreeNode *)[previousOwner childForComponentKey:[node componentKey]] : previousOwner)
                    scopeRoot:scopeRoot
                 stateUpdates:stateUpdates];
  }
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == CKComponentSize(),
           @"CKSingleChildComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@)", size.description(), _childComponent);

  auto const l = [_childComponent layoutThatFits:constrainedSize parentSize:parentSize];
  return {self, l.size, {{{0,0}, l}}};
}

#pragma mark - CKRenderComponent

+ (BOOL)isOwnerComponent
{
  return YES;
}

@end
