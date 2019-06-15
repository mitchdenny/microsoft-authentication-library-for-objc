// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MSALExternalAccountHandler.h"
#import "MSALExternalAccountProviding.h"
#import "MSALTenantProfile.h"
#import "MSALAccount.h"
#import "MSALAADAuthority.h"
#import "MSALResult.h"
#import "MSALAccount+MultiTenantAccount.h"
#import "MSALOauth2Provider.h"
#import "MSALAccount+Internal.h"
#import "MSALErrorConverter.h"

@interface MSALExternalAccountHandler()

@property (nonatomic, nonnull, readwrite) NSArray<id<MSALExternalAccountProviding>> *externalAccountProviders;
@property (nonatomic, nonnull, readwrite) MSALOauth2Provider *oauth2Provider;

@end

@implementation MSALExternalAccountHandler

#pragma mark - Init

- (instancetype)initWithExternalAccountProviders:(NSArray<id<MSALExternalAccountProviding>> *)externalAccountProviders
                                  oauth2Provider:(MSALOauth2Provider *)oauth2Provider
{
    if (![externalAccountProviders count])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, nil, @"No external account providers found");
        return nil;
    }
    
    self = [super init];
    
    if (self)
    {
        _externalAccountProviders = externalAccountProviders;
        _oauth2Provider = oauth2Provider;
    }
    
    return self;
}

#pragma mark - Accounts

- (BOOL)removeAccount:(MSALAccount *)account error:(NSError **)error
{
    for (id<MSALExternalAccountProviding> provider in self.externalAccountProviders)
    {
        NSError *removalError = nil;
        BOOL result = [provider removeAccount:account error:&removalError];
        
        if (!result)
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, nil, @"Failed to remove external account with error %@", MSID_PII_LOG_MASKABLE(removalError));
            
            if (error)
            {
                *error = [MSALErrorConverter msalErrorFromMsidError:removalError];
            }
            
            return NO;
        }
        
        // TODO: remove tenant profiles?
        return YES;
    }
    
    return YES;
}

- (BOOL)updateWithResult:(MSALResult *)result error:(NSError **)error
{
    NSError *updateError = nil;
    MSALAccount *copiedAccount = [result.account copy];
    
    if (result.tenantProfile)
    {
        NSMutableArray *tenantProfiles = [NSMutableArray new];
        [tenantProfiles addObjectsFromArray:copiedAccount.tenantProfiles];
        [tenantProfiles addObject:result.tenantProfile];
        copiedAccount.mTenantProfiles = tenantProfiles;
    }
    
    for (id<MSALExternalAccountProviding> provider in self.externalAccountProviders)
    {
        // TODO: update tenant profiles?
        BOOL result = [provider updateAccount:copiedAccount error:&updateError];
        
        if (!result)
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, nil,  @"Failed to update account with error %@", MSID_PII_LOG_MASKABLE(updateError));
            
            if (error)
            {
                *error = updateError;
            }
            
            return NO;
        }
    }
    
    return YES;
}

- (NSArray<MSALAccount *> *)allExternalAccountsWithParameters:(MSALAccountEnumerationParameters *)parameters
{
    NSMutableArray *allExternalAccounts = [NSMutableArray new];
    
    for (id<MSALExternalAccountProviding> provider in self.externalAccountProviders)
    {
        NSError *externalError = nil;
        NSArray *externalAccounts = [provider accountsWithParameters:parameters error:&externalError];
        
        if (externalError)
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, nil, @"Failed to read external accounts with parameters %@ with error %@", MSID_PII_LOG_MASKABLE(parameters), MSID_PII_LOG_MASKABLE(externalError));
            return nil;
        }
        
        for (id<MSALAccount> externalAccount in externalAccounts)
        {
            MSALAccount *msalAccount = [[MSALAccount alloc] initWithMSALExternalAccount:externalAccount oauth2Provider:self.oauth2Provider];
            
            if (msalAccount)
            {
                [allExternalAccounts addObject:msalAccount];
            }
        }
    }
    
    return allExternalAccounts;
}

@end
