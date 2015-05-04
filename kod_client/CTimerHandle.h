#include "CCPomelo.h"

class CTimerHandle
{
public:
	CTimerHandle(CCPomelo *p) : pomelo(p), running(false)
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
	CCPomelo *pomelo;
	bool running;
};