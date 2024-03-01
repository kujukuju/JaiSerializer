
## WARNING

This project has gone through a lot of changes primarily focused around the very confusing reuse_memory flag.

Things broke and some things that should work don't work and will crash. But for simple serializing and deserializing it should be fine. (And VERY fast when reusing memory.)

I'll refactor and fix everything in the near-ish future.

## Jai Serializer

Serializes structs and data based on the member variables.

Rewrote this recently for big efficiency improvements to memcpy large POD chunks.

Works with directives like #place. (Haven't tested this since the rework but it should still work.) Ignores member variables in byte locations that have already been visited.

Does not yet work with unions, but I intend to allow this to work with unions containing only POD values in the future.

### Reuse Memory Mode

You can use the compile time variable `reuse_memory` to write the memory in such a way that entire chunks can be loaded through pointer offsets.

To use `reuse_memory` you have to both write and read while having the flag enabled. The goal is that you read your file, and then you load the data into your object by just moving pointers around.

The downside of `reuse_memory` is that the data is no longer valid. You can no longer free or realloc pointers, so resizable arrays are completely broken.

So, `reuse_memory` is meant to be used for large constant non-changing like searchable triangle binary trees, or large models/assets.

As an example, the reason I added this method was that loading my giant 300 mb tree of decal triangles was taking about 4 seconds. After loading the decal tree in `reuse_memory` mode it takes about 10 milliseconds.

Example:
```jai
#import "JaiSerializer";

main :: () {
    TypeWithConstant1 :: struct {
        number :: 1;
        not_const: u32;
        const :: 4;
        random: int;
    }

    thing1: TypeWithConstant1;
    thing1.not_const = 1;

    bytes: [..] u8;
    serializer_write(*bytes, thing1);

    thing2: TypeWithConstant1;
    serializer_read(bytes, *thing2);

    print("%\n%\n\n", thing1, thing2);
}
```