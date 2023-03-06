U0 @function_patch(U32 from, U32 to) {
  *(from(U8 *)) = 0xE9;
  *((from + 1)(I32 *)) = to - from - 5;
}

class @function {
  U0(*Patch)
  (U32 from, U32 to);
};

@function Function;
Function.Patch = &@function_patch;

// usage: Function.Patch(&old_func, &new_func);

"function ";