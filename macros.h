#define LogAlloc(ERR,NAME,LEN,SIZE,TAG) CALL LogMemAlloc(NAME,LEN,SIZE,this_routine,TAG)
#define LogDealloc(TAG) CALL LogMemDealloc(this_routine,TAG)
