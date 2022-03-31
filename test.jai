main :: () {
    print("%\n", << type_info(TypeWithConstant1));

    c1: TypeWithConstant2;
    // c1.not_const = 2;
    c1.random = 5;

    bytes: [..] u8;
    Serializer.write(*bytes, c1);

    print("thing1 %\n", c1);
    index: int;
    found, type := Serializer.get_struct_type(bytes, 0, .[TypeWithConstant1, TypeWithConstant2]);
    if type == TypeWithConstant1 {
        c2: TypeWithConstant1;
        Serializer.read(bytes, *index, *c2);
        print("thing2 % %\n", c2, type_of(c2));
    } else if type == TypeWithConstant2 {
        c2: TypeWithConstant2;
        Serializer.read(bytes, *index, *c2);
        print("thing2 % %\n", c2, type_of(c2));
    }

    print("bytes %\n", bytes);
    potential_types :: Type.[TypeWithConstant1, TypeWithConstant2];

    print("Type is: %\n", Serializer.get_struct_type(bytes, 0, potential_types));
}

TypeWithConstant1 :: struct {
    number :: 1;
    not_const: u32;
    const :: 4;
    // other_const: u16 : 2;
    random: int;
}

TypeWithConstant2 :: struct {
    again :: 2;
    random: int;
    const :: 6;
}

#import "Basic";

#load "module.jai";