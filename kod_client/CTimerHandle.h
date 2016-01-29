#include "CTimerHandleDelegate.h"

class CTimerHandle
{
public:
	CTimerHandle(CTimerHandleDelegate *p) : pomelo(p), running(false)
	{}
	~CTimerHandle(){}
	void pause(){
		// printf("%s\n", "pause");
		running = false;
	}
	void resume(){
		// printf("%s\n", "resume");
		running = true;
	}
	void tick(){
		if ( running )
		{
			pomelo->dispatchCallbacks(0);
		}
	}

private:
	CTimerHandleDelegate *pomelo;
	bool running;
};