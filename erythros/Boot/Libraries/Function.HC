U0 @function_insert_call(U32 from, U32 to) {
  *(from(U8 *)) = 0xE8;
  *((from + 1)(I32 *)) = to - from - 5;
}

U0 @function_patch(U32 from, U32 to) {
  *(from(U8 *)) = 0xE9;
  *((from + 1)(I32 *)) = to - from - 5;
}

class @function {
  U0(*InsertCall)
  (U32 from, U32 to);
  U0(*Patch)
  (U32 from, U32 to);
};

@function Function;
Function.InsertCall = &@function_insert_call;
Function.Patch = &@function_patch;

// usage: Function.InsertCall(addr, &func);
// usage: Function.Patch(&old_func, &new_func);

"function ";