#define BUSY 1
#define SPINLOCK_INITIALIZER 0

U8 spinlock = SPINLOCK_INITIALIZER;

U0 spin_lock(U8 *lock)
{
    while (1) {
        if (!LXchgU8(lock, BUSY)) return;
    
        while (*lock) { Sleep(1); }
    }
}

U0 spin_unlock(U8 *lock)
{
    Sleep(RandU16 & 0xFF);
    *lock = 0;
}

U8 spin_trylock(U8 *lock)
{
    return LXchgU8(lock, BUSY);
}
