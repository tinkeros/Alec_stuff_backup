#include  <Uefi.h>
#include  <Library/UefiBootServicesTableLib.h>
#include  <Library/DevicePathLib.h>
#include  <Library/MemoryAllocationLib.h>
#include  <Library/ShellCEntryLib.h>
#include  <Library/ShellLib.h>
#include  <Library/UefiLib.h>
#include  <Protocol/LoadedImage.h>
#include  <Protocol/LoadFile.h>
#include  <Protocol/GraphicsOutput.h>

#include  "stdlib.h"

#define CheckStatus(Status, Code)	{\
	if(EFI_ERROR(Status)){\
		Print(L"Error: Status = %d, LINE=%d in %s\n", (Status), __LINE__, __func__);\
		Code;\
	}\
}

EFI_GRAPHICS_OUTPUT_PROTOCOL            *Gop;

// Wrapper functions for TempleOS: UEFIGopBlt, MAlloc, Free, MSize

void tos_blt(void * ptr)
{
	Gop->Blt(Gop, ptr, EfiBltBufferToVideo, 0, 0, 0, 0, 640, 480, 0);
}

void *tos_malloc(size_t s)
{
	size_t * ret = malloc(sizeof(size_t) + s);
	*ret = s;
	return &ret[1];
}

void tos_free(void * ptr)
{
	free( (size_t*)ptr - 1);
}

size_t tos_msize(void * ptr)
{
	return ((size_t*)ptr)[-1];
}
// ********

EFI_STATUS
EFIAPI
LoadFileByName (
    IN  CONST CHAR16	*FileName,
    OUT UINT8			**FileData,
    OUT UINTN			*FileSize
)
{
	EFI_STATUS					Status;
	SHELL_FILE_HANDLE			FileHandle;
	EFI_FILE_INFO				*Info;
	UINTN						Size;
	UINT8						*Data;

	// Open File by shell protocol
	Status = ShellOpenFileByName(FileName, &FileHandle, EFI_FILE_MODE_READ, 0);
	CheckStatus(Status, return (Status));

	// Get File Info
	Info = ShellGetFileInfo(FileHandle);
	Size = (UINTN)Info->FileSize;
	FreePool(Info);

	// Allocate buffer to read file.
	Data = AllocateRuntimeZeroPool(Size);
	if (Data == NULL) {
		Print(L"Error: AllocateRuntimeZeroPool failed\n");
		return (EFI_OUT_OF_RESOURCES);
	}

	// Read file into Buffer
	Status = ShellReadFile(FileHandle, &Size, Data);
	CheckStatus(Status, return (Status));

	// Close file
	Status = ShellCloseFile(&FileHandle);
	CheckStatus(Status, return (Status));

	*FileSize = Size;
	*FileData = Data;

	return EFI_SUCCESS;
}

// Wrapper function for TempleOS: FileRead

void *tos_fileread(CHAR16 *FileName)
{
	EFI_STATUS                              Status;
	UINT8                                   *FileData;
	Status = LoadFileByName(FileName, &FileData, (UINTN *)0x3050);
	CheckStatus(Status, return ((int *) - 1));
	Print(L"FileRead: %s\n", FileName);
	return &FileData[0];
}

INTN
EFIAPI
ShellAppMain (
    IN UINTN Argc,
    IN CHAR16 **Argv
)
{
	EFI_STATUS				Status;
	CHAR16					*FileName = L"Kernel.BIN.C";
	UINTN					FileSize;
	UINT8					*FileData;
	VOID					*EntryPoint = NULL;
	EFI_HANDLE 				*HandleBuffer = NULL;
	UINTN 					HandleCount = 0;
	BOOLEAN 				LowerHandle = FALSE;


	// Load the file to buffer
	Status = LoadFileByName(FileName, &FileData, &FileSize);
	CheckStatus(Status, return (-1));

	gST->ConOut->ClearScreen( gST->ConOut );
	Print(L"TempleOS UEFI Boot Loader\n\n");
	EntryPoint = (VOID *)0x7C00;
	gBS->CopyMem(EntryPoint, FileData, FileSize);
	Print(L"Loading Kernel.BIN.C\n");



// Try locating GOP by handle
	Status = gBS->LocateHandleBuffer( ByProtocol,
	                                  &gEfiGraphicsOutputProtocolGuid,
	                                  NULL,
	                                  &HandleCount,
	                                  &HandleBuffer);
	if (EFI_ERROR (Status)) {
		Print(L"ERROR: No GOP handles found via LocateHandleBuffer\n");
	} else {
		Print(L"Found %d GOP handles via LocateHandleBuffer\n", HandleCount);
		if (LowerHandle)
			HandleCount = 0;
		else
			HandleCount--;

		Status = gBS->OpenProtocol( HandleBuffer[HandleCount],
		                            &gEfiGraphicsOutputProtocolGuid,
		                            (VOID **)&Gop,
		                            gImageHandle,
		                            NULL,
		                            EFI_OPEN_PROTOCOL_BY_HANDLE_PROTOCOL);
		if (EFI_ERROR (Status)) {
			Print(L"ERROR: OpenProtocol [%d]\n", Status);
		}

		FreePool(HandleBuffer);
	}

	// Set Graphics Output Mode to 640x480x32
	for (int i = 0; i < Gop->Mode->MaxMode; i++) {
		EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *Info;
		UINTN SizeOfInfo;

		Status = Gop->QueryMode(Gop, i, &SizeOfInfo, &Info);
		if (EFI_ERROR(Status) && Status == EFI_NOT_STARTED) {
			Gop->SetMode(Gop, Gop->Mode->Mode);
			Status = Gop->QueryMode(Gop, i, &SizeOfInfo, &Info);
		}
		if (EFI_ERROR(Status)) {
			continue;
		}
		if (Info->HorizontalResolution == 640 && Info->VerticalResolution == 480) {
			{
				Gop->SetMode(Gop, i);
			};
		}
	}

	// Clear Display
	EFI_GRAPHICS_OUTPUT_BLT_PIXEL p;
	p.Red = 0;
	p.Green = 0;
	p.Blue = 0;
	Gop->Blt(Gop, &p, EfiBltVideoFill, 0, 0, 0, 0, 640, 480, 0);

	// Function Pointers
	*(int *) 0x3000 = (long)&tos_malloc;
	*(int *) 0x3010 = (long)&tos_free;
	*(int *) 0x3020 = (long)&tos_msize;
	*(int *) 0x3030 = (long)&tos_blt;
	*(int *) 0x3040 = (long)&tos_fileread;

	// Start TempleOS Kernel
	goto *EntryPoint;

	// Should never get here
	return 0;
}
