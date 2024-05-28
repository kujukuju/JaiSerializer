
main :: () {
    test_pointer: *TypeWithConstant1 = xx 1000;
    assert((cast(int) test_pointer) + 10 == 1010);
    assert((cast(int) (test_pointer + 10)) != 1010);
    assert((cast(int) (cast(*TypeWithConstant1) ((cast(*u8) test_pointer) + 10))) == 1010);
    assert((cast(*TypeWithConstant1) ((cast(*u8) test_pointer) + 10)) == xx 1010);

    OuterThing :: struct {
        inner_thing: ThingWithUnion;
    }

    ThingWithUnion :: struct {
        a: int;
        union {
            b: int;
            c: int;
        }
    }

    #import "KodaJai";

    thing1: ShaderUniform = create_uniform("hey", 2);
    thing1.location = 1;
    bytes1: [..] u8;
    serializer_write(*bytes1, thing1);

    thing2: ShaderUniform;
    serializer_read(bytes1, *thing2);

    print("% % %\n", thing2.name, thing2.location, thing2.uint1);


    UsingThing :: struct {
        using thing: ThingWithUnion;
    }

    thing3: UsingThing;
    thing3.a = 1;
    thing3.b = 2;
    bytes2: [..] u8;
    serializer_write(*bytes2, thing3);

    thing4: UsingThing;
    serializer_read(bytes2, *thing4);

    print("% %\n", thing4.a, thing4.b);

    #import "Math";

    FatEmitterType :: enum {
        One :: 1;
        Two :: 2;
    }

    FatLevelRenderable :: struct {
        name: string;
        geometry: int = -1;
        instances: [..] Matrix4;
    }

    FatLevel :: struct {
        geometries: [..] *Geometry;
        emitters: [..] struct {
            position: Vector3;
            type: FatEmitterType;
        };
        hat_buildings_red: [10] [..] FatLevelRenderable;
    }

    level: FatLevel;
    array_add(*level.geometries, New(Geometry));
    array_add(*level.geometries[0].vertices, 1, 1, 1);
    array_add(*level.emitters, .{.{2, 2, 2}, .Two});
    renderable := array_add(*level.hat_buildings_red[0]);
    renderable.name = "name";
    renderable.geometry = 0;
    array_add(*renderable.instances, Matrix4_Identity);

    bytes3: [..] u8;
    serializer_write(*bytes3, level);

    level2: FatLevel;
    serializer_read(bytes3, *level2);

    print("%\n%\n", level, level2);
    print("%\n%\n", level.geometries[0].*, level2.geometries[0].*);
    print("%\n%\n", level.emitters, level2.emitters);
    print("%\n%\n", level.hat_buildings_red, level2.hat_buildings_red);


    // thing5: SerializeStructure(*Font);
    // bytes3: [..] u8;
    // serializer_write(*bytes3, thing5);

    // thing6: SerializeStructure(*Font);
    // serializer_read(bytes3, *thing6);

    // FontParticleGpu :: struct {}
    // FontParticleCpu :: struct {}
    // thing7: ParticleSystem(FontParticleGpu, FontParticleCpu, sort = false);
    // bytes4: [..] u8;
    // serializer_write(*bytes4, thing7);

    // thing8: ParticleSystem(FontParticleGpu, FontParticleCpu, sort = false);
    // serializer_read(bytes4, *thing8);

    /*

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
        FixedType :: struct {
            data: [100] u8;
        }

        thing1: FixedType;
        for i: 0..99 {
            thing1.data[i] = cast(u8) i;
        }
        bytes: [..] u8;
        serializer_write(*bytes, thing1);

        thing2: FixedType;
        serializer_read(bytes, *thing2);

        print("%\n%\n\n", thing1, thing2);
    }



    {
        FixedType :: struct {
            data: [100] u8;
        }

        thing1: FixedType;
        for i: 0..99 {
            thing1.data[i] = cast(u8) i;
        }
        bytes: [..] u8;
        serializer_write(*bytes, thing1, reuse_memory = true);

        thing2: FixedType;
        serializer_read(bytes, *thing2, reuse_memory = true);

        print("%\n%\n\n", thing1, thing2);
    }



    {
        FixedType :: struct {
            data: [] u8;
        }

        thing1: FixedType;
        thing1.data = NewArray(100, u8);
        for i: 0..99 {
            thing1.data[i] = cast(u8) i;
        }
        bytes: [..] u8;
        serializer_write(*bytes, thing1, reuse_memory = true);

        print("Wrote % bytes.\n", bytes.count);

        thing2: FixedType;
        serializer_read(bytes, *thing2, reuse_memory = true);

        print("%\n%\n\n", thing1, thing2);
    }



    {
        FixedType :: struct {
            data: [100] [] u8;
        }

        thing1: FixedType;
        for i: 0..99 {
            thing1.data[i] = NewArray(i, u8);
            for a: 0..i - 1 {
                thing1.data[i][a] = cast(u8) a;
            }
        }
        bytes: [..] u8;
        serializer_write(*bytes, thing1, reuse_memory = true);

        thing2: FixedType;
        serializer_read(bytes, *thing2, reuse_memory = true);

        print("%\n%\n\n", thing1, thing2);
    }
    */



    // {
    //     #import "KodaJai";

    //     koda_init();

    //     geometry1 := load_geometry("collider.obj", should_upload = false);
    //     bytes: [..] u8;
    //     serializer_write(*bytes, geometry1);

    //     geometry2: *Geometry;
    //     serializer_read(bytes, *geometry2);

    //     print("%\n%\n\n", geometry1.*, geometry2.*);
    // }
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