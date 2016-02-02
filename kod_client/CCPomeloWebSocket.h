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
#define TEST_WEBSOCKET 0 //测试websocket基本功能
#include <map>
#include "openssl/dh.h"

class CTimerHandle;

class CCPomeloWebSocket : public CPomeloProtocol
#if TEST_WEBSOCKET
,public WebSocket::Delegate
#endif
{
public:
    
    enum class HandlerType: int
    {
        NODE = 0,
        MENU_CLICKED,
        CALLFUNC,
        SCHEDULE,
        TOUCHES,
        KEYPAD,
        ACCELEROMETER,
        
        CONTROL_TOUCH_DOWN,
        CONTROL_TOUCH_DRAG_INSIDE,
        CONTROL_TOUCH_DRAG_OUTSIDE,
        CONTROL_TOUCH_DRAG_ENTER,
        CONTROL_TOUCH_DRAG_EXIT,
        CONTROL_TOUCH_UP_INSIDE,
        CONTROL_TOUCH_UP_OUTSIDE,
        CONTROL_TOUCH_UP_CANCEL,
        CONTROL_VALUE_CHANGED,
        
        WEBSOCKET_OPEN,
        WEBSOCKET_MESSAGE,
        WEBSOCKET_CLOSE,
        WEBSOCKET_ERROR,
        
        GL_NODE_DRAW,
        
        SCROLLVIEW_SCROLL,
        SCROLLVIEW_ZOOM,
        
        TABLECELL_TOUCHED,
        TABLECELL_HIGHLIGHT,
        TABLECELL_UNHIGHLIGHT,
        TABLECELL_WILL_RECYCLE,
        TABLECELL_SIZE_FOR_INDEX,
        TABLECELL_AT_INDEX,
        TABLEVIEW_NUMS_OF_CELLS,
        
        XMLHTTPREQUEST_READY_STATE_CHANGE,
        
        ASSETSMANAGER_PROGRESS,
        ASSETSMANAGER_SUCCESS,
        ASSETSMANAGER_ERROR,
        
        STUDIO_EVENT_LISTENER,
        ARMATURE_EVENT,
        
        EVENT_ACC,
        EVENT_CUSTIOM,
        
        EVENT_KEYBOARD_PRESSED,
        EVENT_KEYBOARD_RELEASED,
        
        EVENT_TOUCH_BEGAN,
        EVENT_TOUCH_MOVED,
        EVENT_TOUCH_ENDED,
        EVENT_TOUCH_CANCELLED,
        
        EVENT_TOUCHES_BEGAN,
        EVENT_TOUCHES_MOVED,
        EVENT_TOUCHES_ENDED,
        EVENT_TOUCHES_CANCELLED,
        
        EVENT_MOUSE_DOWN,
        EVENT_MOUSE_UP,
        EVENT_MOUSE_MOVE,
        EVENT_MOUSE_SCROLL,
        
        EVENT_SPINE,
        
        EVENT_PHYSICS_CONTACT_BEGIN,
        EVENT_PHYSICS_CONTACT_PRESOLVE,
        EVENT_PHYSICS_CONTACT_POSTSOLVE,
        EVENT_PHYSICS_CONTACT_SEPERATE,
        
        EVENT_FOCUS,
        
        EVENT_CONTROLLER_CONNECTED,
        EVENT_CONTROLLER_DISCONNECTED,
        EVENT_CONTROLLER_KEYDOWN,
        EVENT_CONTROLLER_KEYUP,
        EVENT_CONTROLLER_KEYREPEAT,
        EVENT_CONTROLLER_AXIS,
        
        EVENT_SPINE_ANIMATION_START,
        EVENT_SPINE_ANIMATION_END,
        EVENT_SPINE_ANIMATION_COMPLETE,
        EVENT_SPINE_ANIMATION_EVENT,
        
        EVENT_CUSTOM_BEGAN = 10000,
        EVENT_CUSTOM_ENDED = 11000,
        };

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
    
    //lua event
    void addHandle(HandlerType handlerType,int handle)
    {
        if(event_function_id_map.find(handlerType)==event_function_id_map.end())
        {
            event_function_id_map.insert(std::make_pair(handlerType, handle));
        }
    }
    
    int getHandle(HandlerType handlerType)
    {
        std::map<HandlerType, int>::iterator itr;
        itr = event_function_id_map.find(handlerType);
        if(itr!=event_function_id_map.end())
        {
            return itr->second;
        }
        return 0;
    }
    
    void removeHandle(HandlerType handlerType)
    {
        std::map<HandlerType, int>::iterator itr;
        itr = event_function_id_map.find(handlerType);
        if(itr!=event_function_id_map.end())
        {
            event_function_id_map.erase(itr);
        }
    }
    
    void removeAllHandles()
    {
        event_function_id_map.clear();
    }
    
    WebSocket * getCurrentWebSocket()
    {
        return m_socket;
    }
    
#if TEST_WEBSOCKET
    //test
    virtual void onOpen(WebSocket* ws) override;
    
    virtual void onMessage(WebSocket* ws, const WebSocket::Data& data) override;
    
    virtual void onClose(WebSocket* ws)override;
    
    virtual void onError(WebSocket* ws, const WebSocket::ErrorCode& error)override;
#endif
    DH* dh;
    void setLuaDH(DH* h){
        if(nullptr!=dh) {
            DH_free(dh);
            dh = nullptr;
        }
        dh = h;
    }
    
    DH* getLuaDH(){return dh;}
        
    void setSelfIndex(int index);
private:
    CTimerHandle *timer_handle;
    int pipe_fd;
    int read_fd;
    int index;
    WebSocket * m_socket;
    std::map<HandlerType, int> event_function_id_map; // type->function
};

#endif /* USE_LUA_WEBSOCKET */
#endif /* CCPomeloWebSocket_hpp */
