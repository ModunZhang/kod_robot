//
//  CTimerHandleDelegate.h
//  kod_client
//
//  Created by DannyHe on 1/29/16.
//  Copyright © 2016 batcat. All rights reserved.
//

#ifndef CTimerHandleDelegate_h
#define CTimerHandleDelegate_h
class CTimerHandleDelegate
{
public:
    virtual ~CTimerHandleDelegate(){};
    virtual void dispatchCallbacks(float delta){};
};

#endif /* CTimerHandleDelegate_h */
