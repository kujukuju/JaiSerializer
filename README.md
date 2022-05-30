## Jai Serializer

Serializes structs and data based on the member variables.

Works with constant values. Writes constants into the byte stream, and skips over them when reading from the byte stream. Probably will add a flag in the future to skip writing completely.

Works with directives like #place. Ignores member variables in byte locations that have already been visited.

Unicode doesn't work yet but I intend to get it working eventually.

Example:
```jai
SERIALIZER: Serializer;
MORE_COMPACT_SERIALIZER: Serializer(u16);

main :: () {
    TypeWithConstant1 :: struct {
        number :: 1;
        not_const: u32;
        random: int;
    }
    
    c1: TypeWithConstant1;
    c1.not_const = 4;
    c1.random = -5;

    bytes: [..] u8;
    SERIALIZER.write(*bytes, c1);

    print("%\n", bytes);

    c2: TypeWithConstant1;
    index: int;
    SERIALIZER.read(bytes, *index, *c2);

    print("%\n", c2);
}
```