#define MAX_FILES 200
#define FILENAME_LEN 12

U8 *extract(File *vol_file, U16 index, U8 *buf, U32 buf_size, U32 *bytesRead)
{
    file_seek(vol_file, index * 20 + FILENAME_LEN);
    U32 offset = file_read4(vol_file);
    U32 size = file_read4(vol_file);
    file_seek(vol_file, offset);

    if (buf == NULL)
    {
        buf = MAlloc(size);
    } else
    {
        if (buf_size < size) {
            size = buf_size;
        }
    }

    file_read_to_buffer(vol_file, buf, size);

    *bytesRead = size;

    return buf;
}

U16 get_index_of_file(File *vol_file, U8 *filename)
{
    U8 volFilenameBuf[FILENAME_LEN+1];

    U16 i=0;
    for(;i<MAX_FILES;i++) {
        file_seek(vol_file, i*20);
        file_read_to_buffer(vol_file, &volFilenameBuf, FILENAME_LEN);
        volFilenameBuf[FILENAME_LEN] = 0;
        if(StrCmp(filename, &volFilenameBuf) == 0) {
            return i;
        }
    }

    return MAX_FILES;
}

U8 *vol_file_extract_by_name(U8 *vol_filename, U8 *filename, U32 *bytesRead)
{
    File vol_file;

    if(!file_open(vol_filename, "rb", &vol_file))
    {
        "Error: opening %s\n", vol_filename;
        return NULL;
    }

    U16 index = get_index_of_file(&vol_file, filename);

    if(index == MAX_FILES)
    {
        return NULL;
    }

    U8 *data = extract(&vol_file, index, NULL, 0, bytesRead);

    file_close(&vol_file);

    return data;
}

U8 *vol_file_load(U8 *vol_filename, U8 *filename, U8 *buffer, U32 buffer_size, U32 *bytesRead)
{
    File vol_file;

    if(!file_open(vol_filename, "rb", &vol_file))
    {
        "Error: opening %s\n", vol_filename;
        return NULL;
    }

    U16 index = get_index_of_file(&vol_file, filename);

    if(index == MAX_FILES)
    {
        file_close(&vol_file);
        return NULL;
    }

    U8 *data = extract(&vol_file, index, buffer, buffer_size, bytesRead);

    file_close(&vol_file);

    return data;
}

Bool vol_file_open(U8 *vol_filename, U8 *filename, File *file)
{
    File vol_file;

    if(!file_open(vol_filename, "rb", &vol_file))
    {
        "Error: opening %s\n", vol_filename;
        return FALSE;
    }

    U16 index = get_index_of_file(&vol_file, filename);

    if(index == MAX_FILES)
    {
        file_close(&vol_file);
        return FALSE;
    }

    file_seek(&vol_file, index * 20 + FILENAME_LEN);
    U32 offset = file_read4(&vol_file);
    U32 size = file_read4(&vol_file);
    file_close(&vol_file);

    if(!file_open_at_offset(vol_filename, "rb", file, offset, size))
    {
        return FALSE;
    }

    return TRUE;
}
