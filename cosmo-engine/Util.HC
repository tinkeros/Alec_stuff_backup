I64 cosmo_rand()
{
    //FIXME
    return RandU64 % 0xffff;
}

I64 Cond(Bool cond, I64 true, I64 false)
{
    if (cond)
        return true;
    return false;
}
