//
//  CCPomeloWebSocket.cpp
//  kod_client
//
//  Created by DannyHe on 1/29/16.
//  Copyright © 2016 batcat. All rights reserved.
//

#include "CCPomeloWebSocket.h"
#include "Common.h"
#if USE_LUA_WEBSOCKET
#include "CTimerHandle.h"

CCPomeloWebSocket::CCPomeloWebSocket() : pipe_fd(-1)
,m_socket(nullptr)
{
    timer_handle = new CTimerHandle(this);
    timer_handle->resume();
#if TEST_WEBSOCKET
    WebSocket* test = new WebSocket();
    registerWebSocket(test);
    test->init(*this, "ws://echo.websocket.org");
#endif
}

CCPomeloWebSocket::~CCPomeloWebSocket()
{
    delete timer_handle;
    timer_handle = nullptr;
}

void CCPomeloWebSocket::dispatchCallbacks(float delta)
{
    CCLOG("\n---dispatchCallbacks:%f---\n",delta);
    if (nullptr!=m_socket) {
        m_socket->update(delta);
    }
}

void CCPomeloWebSocket::setWirtePipeFd(int fd)
{
    pipe_fd = fd;
}

void CCPomeloWebSocket::setReadPipeFd(int fd)
{
    read_fd = fd;
}

int CCPomeloWebSocket::GetSelfIndex()
{
    return 0;
}

int CCPomeloWebSocket::GetReadFd()
{
    return read_fd;
}

CTimerHandle* CCPomeloWebSocket::getTimerHandle()
{
    return timer_handle;
}

#if TEST_WEBSOCKET
//test websocket

void CCPomeloWebSocket::onClose(WebSocket *ws)
{
    CCLOG("[CCPomeloWebSocket::onClose]");
}

void CCPomeloWebSocket::onOpen(WebSocket *ws)
{
    CCLOG("[CCPomeloWebSocket::onOpen]");
    m_socket->send("hello CCPomeloWebSocket");
}

void CCPomeloWebSocket::onMessage(WebSocket *ws, const WebSocket::Data &data)
{
    if(!data.isBinary)
    {
        std::string str = std::string(data.bytes);
        CCLOG("[CCPomeloWebSocket::onMessage]message: %s",str.c_str());
    }
}

void CCPomeloWebSocket::onError(WebSocket *ws, const WebSocket::ErrorCode &error)
{
        CCLOG("CCPomeloWebSocket::onError");
}
#endif
#endif