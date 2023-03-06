class File {
    U8 *filename;
    U8 *data;
    U8 *idata;
    U8 *mode;
    U32 size;
    U32 pos;
    U32 initial_offset;
};

U0 file_close(File *file) {
    if (!StrCmp("wb", file->mode))
    {
        if(file->data)
        {
            FileWrite(file->filename, file->data, file->size);
        }
    }
    if(file->idata)
    {
        Free(file->idata);
        return;
    }
    if(file->data)
    {
        Free(file->data);
    }
}

U32 file_get_current_position(File *file)
{
    if (file)
        return file->pos;
    return 0;
}

U32 file_get_filesize(File *file)
{
    if (file)
        return file->size;
    return 0;
}

Bool file_open(U8 *filename, U8 *mode, File *file) {
    if (!StrCmp("rb", mode))
    {
        if (!FileFind(filename))
        {
            "Failed opening '%s'\n", filename;
            return FALSE;
        }
        file->filename = StrNew(filename);
        file->data = FileRead(filename, &file->size);
        file->idata = NULL;
        file->mode = StrNew(mode);
        file->pos = 0;
        file->initial_offset = 0;
        return TRUE;
    }

    // FIXME: add "wb" mode
    if (!StrCmp("wb", mode))
    {
        file->filename = StrNew(filename);
        file->data = CAlloc(WB_SIZE);
        file->idata = NULL;
        file->mode = StrNew(mode);
        file->pos = 0;
        file->size = 0;
        file->initial_offset = 0;
        return TRUE;
    }

    return FALSE;
}

Bool file_open_at_offset(U8 *filename, U8 *mode, File *file, U32 offset, U32 size)
{
    if (!file_open(filename, mode, file))
    {
        "Failed opening '%s'\n", filename;
        return FALSE;
    }

    if(offset + size >= file->size)
    {
        "Failed opening '%s' offset + size >= actual_size\n", filename;
        file_close(file);
        return FALSE;
    }

    file->idata = file->data;
    file->data = file->idata + offset;
    file->size = size;
    file->pos = 0;
    //file->pos = offset;
    return TRUE;
}

U0 file_seek(File *file, U32 new_position) {
    if(file->data && new_position <= file->size)
    {
        file->pos = new_position;
    }

    return;
}

U32 file_read_to_buffer(File *file, U8 *buf, U32 num_bytes) {
    if(file->pos + num_bytes > file->size)
        num_bytes = file->size - file->pos;

    MemCpy(buf, file->data + file->pos, num_bytes);
    file->pos += num_bytes;

    return num_bytes;
}

U8 file_read1(File *file) {
    if(!file->data || file->pos >= file->size)
        return 0;

    U64 b0 = file->data[file->pos++];
    return b0;
}

U16 file_read2(File *file) {
    if(!file->data || file->pos >= file->size)
        return 0;

    U64 b0 = file->data[file->pos++];
    U64 b1 = file->data[file->pos++];
    return (b0 + (b1<<8));
}

U32 file_read4(File *file) {
    if(!file->data || file->pos >= file->size)
        return 0;

    U64 b0 = file->data[file->pos++];
    U64 b1 = file->data[file->pos++];
    U64 b2 = file->data[file->pos++];
    U64 b3 = file->data[file->pos++];
    return (b0 + (b1<<8) + (b2<<16) + (b3<<24));
}

U0 file_write1(U8 byte, File *file) {
    file->data[file->pos++] = byte;
    if(file->pos > file->size)
        file->size = file->pos;
}

U0 file_write2(U16 word, File *file)
{
    file->data[file->pos++] = word & 0xff;
    file->data[file->pos++] = (word >> 8) & 0xff;
    if(file->pos > file->size)
        file->size = file->pos;
}

U0 file_write4(U32 double_word, File *file)
{
    file->data[file->pos++] = double_word & 0xff;
    file->data[file->pos++] = (double_word >> 8) & 0xff;
    file->data[file->pos++] = (double_word >> 16) & 0xff;
    file->data[file->pos++] = (double_word >> 24) & 0xff;
    if(file->pos > file->size)
        file->size = file->pos;
}