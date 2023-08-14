
main :: () {
    test_pointer: *TypeWithConstant1 = xx 1000;
    assert((cast(int) test_pointer) + 10 == 1010);
    assert((cast(int) (test_pointer + 10)) != 1010);
    assert((cast(int) (cast(*TypeWithConstant1) ((cast(*u8) test_pointer) + 10))) == 1010);
    assert((cast(*TypeWithConstant1) ((cast(*u8) test_pointer) + 10)) == xx 1010);

    {
        thing1: TypeWithConstant1;
        thing1.not_const = 1;

        bytes: [..] u8;
        serializer_write(*bytes, thing1);

        thing2: TypeWithConstant1;
        serializer_read(bytes, *thing2);

        print("%\n%\n\n", thing1, thing2);
    }



    {
        thing1: MoreComplicated;
        array_add(*thing1.data, 1, 2, 3, 4, 5);

        bytes: [..] u8;
        serializer_write(*bytes, thing1);

        thing2: MoreComplicated;
        serializer_read(bytes, *thing2);
        
        print("%\n%\n\n", thing1, thing2);
    }



    {
        thing1: EvenMoreComplicated;
        a := array_add(*thing1.data);
        a.name = sprint("name is %", "apple");
        a.data = New(int);
        a.data.* = 2;
        b := array_add(*thing1.data);
        b.name = sprint("name is %", "orange");
        b.data = New(int);
        b.data.* = 3;
        thing1.followup = true;

        bytes: [..] u8;
        serializer_write(*bytes, thing1);

        thing2: EvenMoreComplicated;
        serializer_read(bytes, *thing2);
        
        print("%\n%\n", thing1, thing2);
        print("% %\n% %\n\n", thing1.data[0].data.*, thing1.data[1].data.*, thing2.data[0].data.*, thing2.data[1].data.*);
    }



    {
        #import "KodaJai";

        koda_init();

        geometry1 := load_geometry("collider.obj", should_upload = false);
        bytes: [..] u8;
        serializer_write(*bytes, geometry1);

        geometry2: *Geometry;
        serializer_read(bytes, *geometry2);

        print("%\n%\n\n", geometry1.*, geometry2.*);
    }
}

// main :: () {
//     print("%\n", << type_info(TypeWithConstant1));

//     c1: TypeWithConstant2;
//     // c1.not_const = 2;
//     c1.random = 5;

//     bytes: [..] u8;
//     write(*bytes, c1);

//     print("thing1 %\n", c1);
//     found, type := get_struct_type(bytes, 0, .[TypeWithConstant1, TypeWithConstant2]);
//     if type == TypeWithConstant1 {
//         c2: TypeWithConstant1;
//         read(bytes, *index, *c2);
//         print("thing2 % %\n", c2, type_of(c2));
//     } else if type == TypeWithConstant2 {
//         c2: TypeWithConstant2;
//         read(bytes, *index, *c2);
//         print("thing2 % %\n", c2, type_of(c2));
//     }

//     print("bytes %\n", bytes);
//     potential_types :: Type.[TypeWithConstant1, TypeWithConstant2];

//     print("Type is: %\n", get_struct_type(bytes, 0, potential_types));
// }

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

MoreComplicated :: struct {
    data: [..] int;
}

EvenMoreComplicated :: struct {
    EvenMoreComplicatedInner :: struct {
        name: string;
        data: *int;
    }

    data: [..] EvenMoreComplicatedInner;
    followup: bool;
}

#import "Basic";

#import "JaiSerializer";