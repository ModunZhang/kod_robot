//
//
//  Created by xudexin on 13-4-17.
//
//
#if (USE_LUA_WEBSOCKET == 0)
#ifndef __CCPomelo__
#define __CCPomelo__


#include "../lua_engine/CCLuaEngine.h"
#include "jansson.h"
#include "pomelo.h"
#include <map>
#include <string>
#include <queue>
#include <sys/socket.h>
#include "CPomeloProtocol.h"

class CTimerHandle;
class CCPomeloContent_;
class CCPomeloReponse_;
class CCPomeloEvent_ ;
class CCPomeloNotify_;
class CCPomeloConnect_;
class CCPomeloReponse;

using namespace std;
typedef std::function<void(const CCPomeloReponse&)> PomeloCallback;


class CCPomeloReponse{
public:
    CCPomeloReponse(){}
    ~CCPomeloReponse(){}
    int status;
    json_t *docs;
};




class CCPomelo : public CPomeloProtocol{
public:
    // static CCPomelo *getInstance();
    // static void destroyInstance();

    CTimerHandle * getTimerHandle(){
        return timer_handle;
    }
    
    int connect(const char* addr,int port);
    void asyncConnect(const char* addr,int port, const PomeloCallback& callback);
    void stop();

    int request(const char*route,json_t *msg, const PomeloCallback& callback);
    int notify(const char*route,json_t *msg, const PomeloCallback& callback);
    int addListener(const char* event, const PomeloCallback& callback);
    void removeListener(const char* event);

public:
    CCPomelo();
    virtual ~CCPomelo();
        
    static CCPomelo* GetPomeloByIndex(int index);
    int GetSelfIndex() {
        for (int i = 0; i < CCPomelo::MAX_POMELO_CLIENTS; ++i)
        {
            if( _pomelos[i] == this )
            {
                return i;
            }
        }
        return -1;
    }
    int GetReadFd()
    {
        return read_fd;
    }
    void setReadPipeFd(int fd)
    {
        read_fd = fd;
    }
    void setWirtePipeFd(int fd)
    {
        pipe_fd = fd;
    }
    void sendSignal(){
        char sig = GetSelfIndex() + 100;
        send(pipe_fd, &sig, sizeof(sig), 0);
    }
    
    void cleanup();
    
    void cleanupEventContent();
    void cleanupNotifyContent();
    void cleanupRequestContent();
    
    virtual void dispatchCallbacks(float delta) override;
    
    
    void lockReponsQeueue();
    void unlockReponsQeueue();
    void lockEventQeueue();
    void unlockEventQeueue();
    void lockNotifyQeueue();
    void unlockNotifyQeueue();
    
    void lockConnectContent();
    void unlockConnectContent();
    
    
    void pushReponse(CCPomeloReponse_*resp);
    void pushEvent(CCPomeloEvent_*ev);
    void pushNotiyf(CCPomeloNotify_*ntf);
    void connectCallBack(int status);

private:
    void incTaskCount();
    void desTaskCount();
    
    CCPomeloReponse_*popReponse();
    CCPomeloEvent_*popEvent();
    CCPomeloNotify_*popNotify();
    
    std::map<pc_notify_t*,CCPomeloContent_*> notify_content;
    pthread_mutex_t  notify_queue_mutex;
    std::queue<CCPomeloNotify_*> notify_queue;
    
    std::map<std::string,CCPomeloContent_*> event_content;
    pthread_mutex_t  event_queue_mutex;
    std::queue<CCPomeloEvent_*> event_queue;
    
    std::map<pc_request_t *,CCPomeloContent_*> request_content;
    pthread_mutex_t  reponse_queue_mutex;
    std::queue<CCPomeloReponse_*> reponse_queue;
    
    
    pthread_mutex_t  connect_mutex;
    CCPomeloConnect_* connect_content;
    
    
    pthread_mutex_t  task_count_mutex;
    void dispatchRequest();
    void dispatchEvent();
    void dispatchNotify();
    void connectCallBack();
    pc_client_t *client;
    int task_count;
    int connect_status;

    CTimerHandle *timer_handle;
    int pipe_fd;
    int read_fd;

    static const int MAX_POMELO_CLIENTS = 10;
    static CCPomelo *_pomelos[MAX_POMELO_CLIENTS];
};

#endif /* defined(__CCPomelo__) */
#endif /*USE_LUA_WEBSOCKET*/