#include "CPomeloProtocol.h"

class CTimerHandle
{
public:
	CTimerHandle(CPomeloProtocol *p) : pomelo(p), running(false)
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
	CPomeloProtocol *pomelo;
	bool running;
};