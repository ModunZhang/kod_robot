//
//  ProtocolHandler.cpp
//  Ragnarok Battle Online
//
//  Created by xudexin on 13-4-17.
//
//

#include "CTimerHandle.h"
#include "CCPomelo.h"
#include <errno.h>
#include <assert.h>



#define CCLOG(format, ...) fprintf(stdout, format, ##__VA_ARGS__);printf("\n")

CCPomelo * CCPomelo::_pomelos[] = {};

class CCPomeloContent_ {
public:
    CCPomeloContent_(){
        callback = NULL;
    }
    ~CCPomeloContent_(){
        
    }
    
    PomeloCallback callback;
};
class CCPomeloReponse_ {
public:
    CCPomeloReponse_(){
        request = NULL;
        docs = NULL;
    }
    ~CCPomeloReponse_(){
        
    }
    int status;
    pc_request_t *request;
    json_t *docs;
};
class CCPomeloEvent_ {
public:
    CCPomeloEvent_():status(0)
    {
        docs = NULL;
    }
    ~CCPomeloEvent_(){
        
    }
    int status;
    std::string event;
    json_t *docs;
};
class CCPomeloNotify_ {
public:
    CCPomeloNotify_(){
        notify = NULL;
    }
    ~CCPomeloNotify_(){
        
    }
    int status;
    pc_notify_t *notify;
};

class CCPomeloConnect_ {
public:
    CCPomeloConnect_(){
        req = NULL;
    }
    ~CCPomeloConnect_(){
        
    }
    int status;
    pc_connect_t *req;
    CCPomeloContent_ *content;
};

// static CCPomelo *s_CCPomelo = NULL; // pointer to singleton



#define cc_pomelo_on_ansync_connect_cb(x) void \
cc_pomelo_on_ansync_connect_cb##x \
(pc_connect_t* conn_req, int status){ \
    if (conn_req) { \
        pc_connect_req_destroy(conn_req); \
    } \
    if(!CCPomelo::GetPomeloByIndex(x)) return ; \
    CCPomelo::GetPomeloByIndex(x)->connectCallBack(status); \
}
cc_pomelo_on_ansync_connect_cb(0);
cc_pomelo_on_ansync_connect_cb(1);
cc_pomelo_on_ansync_connect_cb(2);
cc_pomelo_on_ansync_connect_cb(3);
cc_pomelo_on_ansync_connect_cb(4);
cc_pomelo_on_ansync_connect_cb(5);
cc_pomelo_on_ansync_connect_cb(6);
cc_pomelo_on_ansync_connect_cb(7);
cc_pomelo_on_ansync_connect_cb(8);
cc_pomelo_on_ansync_connect_cb(9);
typedef void (*cc_pomelo_on_ansync_connect_cb)(pc_connect_t*, int);
static cc_pomelo_on_ansync_connect_cb cc_pomelo_on_ansync_connect_cb_array[] = {
    cc_pomelo_on_ansync_connect_cb0,
    cc_pomelo_on_ansync_connect_cb1,
    cc_pomelo_on_ansync_connect_cb2,
    cc_pomelo_on_ansync_connect_cb3,
    cc_pomelo_on_ansync_connect_cb4,
    cc_pomelo_on_ansync_connect_cb5,
    cc_pomelo_on_ansync_connect_cb6,
    cc_pomelo_on_ansync_connect_cb7,
    cc_pomelo_on_ansync_connect_cb8,
    cc_pomelo_on_ansync_connect_cb9
};


#define cc_pomelo_on_notify_cb(x) void \
cc_pomelo_on_notify_cb##x(pc_notify_t *ntf, int status){ \
    if(!CCPomelo::GetPomeloByIndex(x)) return ; \
    CCPomelo * pomelo = CCPomelo::GetPomeloByIndex(x); \
\
    pomelo->lockNotifyQeueue(); \
\
    CCPomeloNotify_ *notify = new CCPomeloNotify_; \
    notify->notify = ntf; \
    notify->status = status; \
\
    pomelo->pushNotiyf(notify); \
\
    pomelo->unlockNotifyQeueue(); \
\    
    pomelo->sendSignal(); \
}
cc_pomelo_on_notify_cb(0);
cc_pomelo_on_notify_cb(1);
cc_pomelo_on_notify_cb(2);
cc_pomelo_on_notify_cb(3);
cc_pomelo_on_notify_cb(4);
cc_pomelo_on_notify_cb(5);
cc_pomelo_on_notify_cb(6);
cc_pomelo_on_notify_cb(7);
cc_pomelo_on_notify_cb(8);
cc_pomelo_on_notify_cb(9);
typedef void (*cc_pomelo_on_notify_cb)(pc_notify_t *, int);
static cc_pomelo_on_notify_cb cc_pomelo_on_notify_cb_array[] = {
    cc_pomelo_on_notify_cb0,
    cc_pomelo_on_notify_cb1,
    cc_pomelo_on_notify_cb2,
    cc_pomelo_on_notify_cb3,
    cc_pomelo_on_notify_cb4,
    cc_pomelo_on_notify_cb5,
    cc_pomelo_on_notify_cb6,
    cc_pomelo_on_notify_cb7,
    cc_pomelo_on_notify_cb8,
    cc_pomelo_on_notify_cb9
};




#define cc_pomelo_on_event_cb(x) void \
cc_pomelo_on_event_cb##x(pc_client_t *client, const char *event, void *data) { \
    if(!CCPomelo::GetPomeloByIndex(x)) return ; \
    CCPomelo *pomelo = CCPomelo::GetPomeloByIndex(x); \
    pomelo->lockEventQeueue(); \
\
    CCPomeloEvent_ *ev = new CCPomeloEvent_; \
    ev->event = event; \
    ev->docs = (json_t *)data;\
    json_incref(ev->docs);\
    \
    pomelo->pushEvent(ev);\
    \
    pomelo->unlockEventQeueue();\
    \
    pomelo->sendSignal();\
}
cc_pomelo_on_event_cb(0);
cc_pomelo_on_event_cb(1);
cc_pomelo_on_event_cb(2);
cc_pomelo_on_event_cb(3);
cc_pomelo_on_event_cb(4);
cc_pomelo_on_event_cb(5);
cc_pomelo_on_event_cb(6);
cc_pomelo_on_event_cb(7);
cc_pomelo_on_event_cb(8);
cc_pomelo_on_event_cb(9);
typedef void (*cc_pomelo_on_event_cb)(pc_client_t *, const char *, void *);
static cc_pomelo_on_event_cb cc_pomelo_on_event_cb_array[] = {
    cc_pomelo_on_event_cb0,
    cc_pomelo_on_event_cb1,
    cc_pomelo_on_event_cb2,
    cc_pomelo_on_event_cb3,
    cc_pomelo_on_event_cb4,
    cc_pomelo_on_event_cb5,
    cc_pomelo_on_event_cb6,
    cc_pomelo_on_event_cb7,
    cc_pomelo_on_event_cb8,
    cc_pomelo_on_event_cb9
};




#define cc_pomelo_on_request_cb(x) void \
cc_pomelo_on_request_cb##x(pc_request_t *request, int status, json_t *docs) { \
    if(!CCPomelo::GetPomeloByIndex(x)) return ; \
    CCPomelo *pomelo = CCPomelo::GetPomeloByIndex(x); \
    pomelo->lockReponsQeueue();\
    \
    CCPomeloReponse_ *response = new CCPomeloReponse_;\
    response->request = request;\
    response->status = status;\
    response->docs = docs;\
    json_incref(docs);\
    \
    pomelo->pushReponse(response);\
    \
    pomelo->unlockReponsQeueue();\
    \
    pomelo->sendSignal();\
}
cc_pomelo_on_request_cb(0);
cc_pomelo_on_request_cb(1);
cc_pomelo_on_request_cb(2);
cc_pomelo_on_request_cb(3);
cc_pomelo_on_request_cb(4);
cc_pomelo_on_request_cb(5);
cc_pomelo_on_request_cb(6);
cc_pomelo_on_request_cb(7);
cc_pomelo_on_request_cb(8);
cc_pomelo_on_request_cb(9);
typedef void (*cc_pomelo_on_request_cb)(pc_request_t *, int, json_t *);
static cc_pomelo_on_request_cb cc_pomelo_on_request_cb_array[] = {
    cc_pomelo_on_request_cb0,
    cc_pomelo_on_request_cb1,
    cc_pomelo_on_request_cb2,
    cc_pomelo_on_request_cb3,
    cc_pomelo_on_request_cb4,
    cc_pomelo_on_request_cb5,
    cc_pomelo_on_request_cb6,
    cc_pomelo_on_request_cb7,
    cc_pomelo_on_request_cb8,
    cc_pomelo_on_request_cb9
};



CCPomelo* CCPomelo::GetPomeloByIndex(int index) {
    assert(index >= 0 && index < CCPomelo::MAX_POMELO_CLIENTS);
    assert(CCPomelo::_pomelos[index]);
    return CCPomelo::_pomelos[index];
}


CCPomelo::CCPomelo()
{
    pipe_fd = -1;
    timer_handle = new CTimerHandle(this);
    timer_handle->pause();
    pthread_mutex_init(&reponse_queue_mutex, NULL);
    pthread_mutex_init(&event_queue_mutex, NULL);
    pthread_mutex_init(&notify_queue_mutex, NULL);
    pthread_mutex_init(&task_count_mutex, NULL);
    pthread_mutex_init(&connect_mutex, NULL);
    task_count = 0;
    connect_status = 0;
    connect_content = NULL;
    client = NULL;

    for (int i = 0; i < CCPomelo::MAX_POMELO_CLIENTS; ++i)
    {
        if( _pomelos[i] == 0 )
        {
            _pomelos[i] = this;
            break;
        }
    }
}
CCPomelo::~CCPomelo(){
    for (int i = 0; i < CCPomelo::MAX_POMELO_CLIENTS; ++i)
    {
        if( _pomelos[i] == this )
        {
            _pomelos[i] = 0;
            break;
        }
    }
    delete timer_handle;
}

void CCPomelo::dispatchRequest(){
    lockReponsQeueue();
    CCPomeloReponse_ *response = popReponse();
    if (response) {
        CCPomeloContent_ * content = NULL;
        if (request_content.find(response->request)!=request_content.end()) {
            content = request_content[response->request];
            request_content.erase(response->request);
        }
        if (content && content->callback) {
            CCPomeloReponse resp;
            resp.status = response->status;
            resp.docs = response->docs;
            content->callback(resp);
        }else{
            CCLOG("dispatch response:\r\nlost content");
        }
        json_decref(response->docs);
        json_decref(response->request->msg);
        pc_request_destroy(response->request);
        delete response;
    }
    unlockReponsQeueue();
}
void CCPomelo::dispatchEvent(){
    lockEventQeueue();
    CCPomeloEvent_ *event = popEvent();
    if (event) {
        CCPomeloContent_ * content = NULL;
        if (event_content.find(event->event)!=event_content.end()) {
            content = event_content[event->event];
        }
        if (content && content->callback) {
            CCPomeloReponse resp;
            resp.status = event->status;
            resp.docs = event->docs;
            content->callback(resp);
        }else{
            CCLOG("dispatch event::\r\n lost %s content",event->event.c_str());
        }
        json_decref(event->docs);
        delete event;
    }
    unlockEventQeueue();
}
void CCPomelo::dispatchNotify(){
    lockNotifyQeueue();
    CCPomeloNotify_ *ntf = popNotify();
    if (ntf) {
        CCPomeloContent_ * content = NULL;
        if (notify_content.find(ntf->notify)!=notify_content.end()) {
            content = notify_content[ntf->notify];
            notify_content.erase(ntf->notify);
        }
        if (content && content->callback) {
            CCPomeloReponse resp;
            resp.status = ntf->status;
            resp.docs = NULL;
            content->callback(resp);
        }else{
            CCLOG("dispatch notify:\r\nlost content");
        }
        json_decref(ntf->notify->msg);
        pc_notify_destroy(ntf->notify);
        delete ntf;
    }
    unlockNotifyQeueue();
}

void CCPomelo::connectCallBack(){
    if (connect_content) {
        if (connect_content->content && connect_content->content->callback)
        {
            CCPomeloReponse resp;
            resp.status = connect_content->status;
            resp.docs = NULL;
            connect_content->content->callback(resp);
        }
        connect_status  = 0;
        desTaskCount();
        delete connect_content;
        connect_content = NULL;
    }
   
}
void CCPomelo::dispatchCallbacks(float delta){
    // printf("%s\n", "dispatchCallbacks");
    dispatchNotify();
    dispatchEvent();
    dispatchRequest();
    if (connect_status==1) {
        connectCallBack();
    }
    
    pthread_mutex_lock(&task_count_mutex);
    
    if (task_count==0) {
        timer_handle->pause();
    }
    pthread_mutex_unlock(&task_count_mutex);
    
}

// void CCPomelo::destroyInstance()
// {
//     if (s_CCPomelo) {
//         delete s_CCPomelo;
//         s_CCPomelo = NULL;
//     }
// }

// CCPomelo* CCPomelo::getInstance()
// {
//     if (s_CCPomelo == NULL) {
//         s_CCPomelo = new CCPomelo();
//     }
//     return s_CCPomelo;
// }

int CCPomelo::connect(const char* addr,int port){
    struct sockaddr_in address;
    memset(&address, 0, sizeof(struct sockaddr_in));
    address.sin_family = AF_INET;
    address.sin_port = htons(port);
    address.sin_addr.s_addr = inet_addr(addr);
    
    client = pc_client_new();
   
    int ret = pc_client_connect(client, &address);
    if(ret) {
        CCLOG("pc_client_connect error:%d",errno);
        pc_client_destroy(client);
    }
    return  ret;
}
void CCPomelo::asyncConnect(const char* addr,int port, const PomeloCallback& callback){
   
    if (!connect_content) {
        connect_status = 0;
        connect_content = new CCPomeloConnect_;
        connect_content->content = new CCPomeloContent_;
        connect_content->content->callback = callback;
    }else{
        CCLOG("can not call again before the first connect callback");
        return ;
    }
    
    struct sockaddr_in address;
    memset(&address, 0, sizeof(struct sockaddr_in));
    address.sin_family = AF_INET;
    address.sin_port = htons(port);
    address.sin_addr.s_addr = inet_addr(addr);
    
    client = pc_client_new();
    pc_connect_t* async = pc_connect_req_new(&address);

    int index = GetSelfIndex();
    assert(index >= 0);
    cc_pomelo_on_ansync_connect_cb cb = cc_pomelo_on_ansync_connect_cb_array[index];
    int ret = pc_client_connect2(client,async,cb);
    if(ret) {
        CCLOG("pc_client_connect2 error:%d",errno);
        pc_client_destroy(client);
        cb(NULL,ret);
    }

}


void CCPomelo::stop(){
    if(client){
//      pc_client_stop(client);
        pc_client_destroy(client);
    }
}
void CCPomelo::cleanup(){
    cleanupEventContent();
    cleanupNotifyContent();
    cleanupRequestContent();
    pthread_mutex_lock(&task_count_mutex);
    pthread_mutex_unlock(&task_count_mutex);
}

void CCPomelo::cleanupEventContent(){
    std::map<std::string,CCPomeloContent_*>::iterator iter;
    
    int index = GetSelfIndex();
    assert(index >= 0);
    cc_pomelo_on_event_cb cb = cc_pomelo_on_event_cb_array[index];

    for (iter = event_content.begin();iter != event_content.end();iter++) {
        CCPomeloContent_ *content = iter->second;
        delete  content;
        pc_remove_listener(client, iter->first.c_str(), cb);
    }
    event_content.clear();
}
void CCPomelo::cleanupNotifyContent(){
    std::map<pc_notify_t*,CCPomeloContent_*>::iterator iter;
    for (iter = notify_content.begin();iter != notify_content.end();iter++) {
        CCPomeloContent_ *content = iter->second;
        delete  content;
    }
    notify_content.clear();
}
void CCPomelo::cleanupRequestContent(){
    std::map<pc_request_t *,CCPomeloContent_*>::iterator iter;
    for (iter = request_content.begin();iter != request_content.end();iter++) {
        CCPomeloContent_ *content = iter->second;
        delete  content;
    }
    request_content.clear();
}

int CCPomelo::request(const char*route,json_t *msg, const PomeloCallback& callback){
    
    pc_request_t *req   = pc_request_new();
    CCPomeloContent_ *content = new CCPomeloContent_;
    content->callback = callback;
    request_content[req] = content;

    int index = GetSelfIndex();
    assert(index >= 0);
    cc_pomelo_on_request_cb cb = cc_pomelo_on_request_cb_array[index];

    return pc_request(client,req, route, json_deep_copy(msg), cb);
}

int CCPomelo::notify(const char*route,json_t *msg, const PomeloCallback& callback){
    
    pc_notify_t *notify = pc_notify_new();
    CCPomeloContent_ *content = new CCPomeloContent_;
    content->callback = callback;
    notify_content[notify] = content;


    int index = GetSelfIndex();
    assert(index >= 0);
    cc_pomelo_on_notify_cb cb = cc_pomelo_on_notify_cb_array[index];
    return pc_notify(client,notify, route, json_deep_copy(msg), cb);
}

int CCPomelo::addListener(const char* event, const PomeloCallback& callback){
    CCPomeloContent_ *content = new CCPomeloContent_;
    content->callback = callback;
    if (event_content.find(event)!=event_content.end()) {
        delete  event_content[event];
    }
    event_content[event] = content;


    int index = GetSelfIndex();
    assert(index >= 0);
    cc_pomelo_on_event_cb cb = cc_pomelo_on_event_cb_array[index];

    return pc_add_listener(client, event, cb);
}
void CCPomelo::removeListener(const char *event){
    if (event_content.find(event)!=event_content.end()) {
        delete  event_content[event];
        event_content.erase(event);

        int index = GetSelfIndex();
        assert(index >= 0);
        cc_pomelo_on_event_cb cb = cc_pomelo_on_event_cb_array[index];

        pc_remove_listener(client, event, cb);
    }
}
void CCPomelo::incTaskCount(){
    pthread_mutex_lock(&task_count_mutex);
    task_count++;
    pthread_mutex_unlock(&task_count_mutex);
    timer_handle->resume();
}
void CCPomelo::desTaskCount(){
    pthread_mutex_lock(&task_count_mutex);
    task_count--;
    pthread_mutex_unlock(&task_count_mutex);
}

void CCPomelo::lockReponsQeueue(){
    pthread_mutex_lock(&reponse_queue_mutex);
}

void CCPomelo::unlockReponsQeueue(){
    pthread_mutex_unlock(&reponse_queue_mutex);
}

void CCPomelo::lockEventQeueue(){
    pthread_mutex_lock(&event_queue_mutex);
}

void CCPomelo::unlockEventQeueue(){
    pthread_mutex_unlock(&event_queue_mutex);
}

void CCPomelo::lockNotifyQeueue(){
    pthread_mutex_lock(&notify_queue_mutex);
}

void CCPomelo::unlockNotifyQeueue(){
    pthread_mutex_unlock(&notify_queue_mutex);
}
void CCPomelo::lockConnectContent(){
    pthread_mutex_unlock(&connect_mutex);
}
void CCPomelo::unlockConnectContent(){
    pthread_mutex_unlock(&connect_mutex);
}

void CCPomelo::pushReponse(CCPomeloReponse_*response){
    reponse_queue.push(response);
    incTaskCount();
}
void CCPomelo::pushEvent(CCPomeloEvent_* event){
    event_queue.push(event);
    incTaskCount();
}
void CCPomelo::pushNotiyf(CCPomeloNotify_*notify){
    notify_queue.push(notify);
    incTaskCount();
}
void CCPomelo::connectCallBack(int status){
    connect_status = 1;
    connect_content->status = status;
    incTaskCount();
}
CCPomeloReponse_*CCPomelo::popReponse(){
    if (reponse_queue.size()>0) {
        CCPomeloReponse_ *response = reponse_queue.front();
        reponse_queue.pop();
        desTaskCount();
        return  response;
    }else{
        return  NULL;
    }
}
CCPomeloEvent_*CCPomelo::popEvent(){
    if (event_queue.size()>0) {
        CCPomeloEvent_ *event = event_queue.front();
        event_queue.pop();
        desTaskCount();
        return  event;
    }else{
        return  NULL;
    }
}
CCPomeloNotify_*CCPomelo::popNotify(){
    if (notify_queue.size()>0) {
        CCPomeloNotify_ *ntf = notify_queue.front();
        notify_queue.pop();
        desTaskCount();
        return  ntf;
    }else{
        return  NULL;
    }
}