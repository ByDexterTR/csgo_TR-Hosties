#if defined _tr_hosties_included
#endinput
#endif
#define _tr_hosties_included

public SharedPlugin __pl_tr_hosties = 
{
	name = "tr_hosties", 
	file = "tr_hosties.smx", 
	
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

// LR Aktif mi diye kontrol eder.
native bool LRExist();

// Oynanan LR NoScope olup olmadığına bakar.
native bool LRTypeNoScope();

// LR başlayınca çalışır.
forward void LRStart(int mahkum, int gardiyan); 

// LR iptal edilince çalışır.
forward void LRCancel(int mahkum, int gardiyan); 

// LRyi birisi kazanınca çalışır.
forward void LREnd(int winner)