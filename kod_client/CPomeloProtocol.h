//
//  CTimerHandleDelegate.h
//  kod_client
//
//  Created by DannyHe on 1/29/16.
//  Copyright © 2016 batcat. All rights reserved.
//

#ifndef CTimerHandleDelegate_h
#define CTimerHandleDelegate_h
class CTimerHandle;
class CPomeloProtocol
{
public:
    
    virtual void dispatchCallbacks(float delta) = 0;
    
    virtual void setWirtePipeFd(int fd) = 0;
    
    virtual void setReadPipeFd(int fd) = 0;
    
    virtual int  GetSelfIndex() = 0;
    
    virtual int  GetReadFd() = 0;
    
    virtual CTimerHandle* getTimerHandle() = 0;
    
    virtual ~CPomeloProtocol() {};
};

#endif /* CTimerHandleDelegate_h */
