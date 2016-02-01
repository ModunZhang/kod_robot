//
//  CCPomeloWebSocket.hpp
//  kod_client
//
//  Created by DannyHe on 1/29/16.
//  Copyright © 2016 batcat. All rights reserved.
//

#ifndef CCPomeloWebSocket_hpp
#define CCPomeloWebSocket_hpp
#if USE_LUA_WEBSOCKET
#include "CPomeloProtocol.h"
#include "WebSocket.h"
#define TEST_WEBSOCKET 1 //测试websocket基本功能


class CTimerHandle;

class CCPomeloWebSocket : public CPomeloProtocol
#if TEST_WEBSOCKET
,public WebSocket::Delegate
#endif
{
public:
    CCPomeloWebSocket();
    ~CCPomeloWebSocket();
    
    //CPomeloProtocol
    virtual void dispatchCallbacks(float delta) override;
    virtual void setWirtePipeFd(int fd) override;
    virtual void setReadPipeFd(int fd) override;
    virtual int  GetSelfIndex()override;
    virtual int  GetReadFd()override;
    virtual CTimerHandle* getTimerHandle() override;
    //websockets
    
    void registerWebSocket(WebSocket* _webSocket){m_socket = _webSocket;};
    void unRegisterWebSocket(){m_socket = nullptr;};
#if TEST_WEBSOCKET
    //test
    virtual void onOpen(WebSocket* ws) override;
    
    virtual void onMessage(WebSocket* ws, const WebSocket::Data& data) override;
    
    virtual void onClose(WebSocket* ws)override;
    
    virtual void onError(WebSocket* ws, const WebSocket::ErrorCode& error)override;
#endif
private:
    CTimerHandle *timer_handle;
    int pipe_fd;
    int read_fd;
    WebSocket * m_socket;
};

#endif /* USE_LUA_WEBSOCKET */
#endif /* CCPomeloWebSocket_hpp */
