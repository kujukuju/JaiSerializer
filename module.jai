Serializer :: struct (count_type: Type = int, unicode_strings: bool = false) {
    read :: (bytes: [] u8, index: *int, value: *bool) {
        assert(<< index + 1 <= bytes.count);

        << value = << cast(*bool) *bytes[<< index];
        << index += 1;
    }

    write :: (bytes: *[..] u8, value: bool) {
        array_add(bytes, cast(u8) value);
    }

    read :: (bytes: [] u8, index: *int, value: *u8) {
        assert(<< index + 1 <= bytes.count);

        << value = << cast(*u8) *bytes[<< index];
        << index += 1;
    }

    write :: (bytes: *[..] u8, value: u8) {
        array_add(bytes, value);
    }

    read :: (bytes: [] u8, index: *int, value: *s8) {
        assert(<< index + 1 <= bytes.count);

        << value = << cast(*s8) *bytes[<< index];
        << index += 1;
    }

    write :: (bytes: *[..] u8, value: s8) {
        byte: *u8 = xx *value;
        array_add(bytes, << byte);
    }

    read :: (bytes: [] u8, index: *int, value: *u16) {
        assert(<< index + 2 <= bytes.count);

        << value = << cast(*u16) *bytes[<< index];
        << index += 2;
    }

    write :: (bytes: *[..] u8, value: u16) {
        byte: *u8 = xx *value;
        for i: 0..1 {
            array_add(bytes, << (byte + i));
        }
    }

    read :: (bytes: [] u8, index: *int, value: *s16) {
        assert(<< index + 2 <= bytes.count);

        << value = << cast(*s16) *bytes[<< index];
        << index += 2;
    }

    write :: (bytes: *[..] u8, value: s16) {
        byte: *u8 = xx *value;
        for i: 0..1 {
            array_add(bytes, << (byte + i));
        }
    }

    read :: (bytes: [] u8, index: *int, value: *u32) {
        assert(<< index + 4 <= bytes.count);

        << value = << cast(*u32) *bytes[<< index];
        << index += 4;
    }

    write :: (bytes: *[..] u8, value: u32) {
        byte: *u8 = xx *value;
        for i: 0..3 {
            array_add(bytes, << (byte + i));
        }
    }

    read :: (bytes: [] u8, index: *int, value: *s32) {
        assert(<< index + 4 <= bytes.count);

        << value = << cast(*s32) *bytes[<< index];
        << index += 4;
    }

    write :: (bytes: *[..] u8, value: s32) {
        byte: *u8 = xx *value;
        for i: 0..3 {
            array_add(bytes, << (byte + i));
        }
    }

    read :: (bytes: [] u8, index: *int, value: *u64) {
        assert(<< index + 8 <= bytes.count);

        << value = << cast(*u64) *bytes[<< index];
        << index += 8;
    }

    write :: (bytes: *[..] u8, value: u64) {
        byte: *u8 = xx *value;
        for i: 0..7 {
            array_add(bytes, << (byte + i));
        }
    }

    read :: (bytes: [] u8, index: *int, value: *s64) {
        assert(<< index + 8 <= bytes.count);

        << value = << cast(*s64) *bytes[<< index];
        << index += 8;
    }

    write :: (bytes: *[..] u8, value: s64) {
        byte: *u8 = xx *value;
        for i: 0..7 {
            array_add(bytes, << (byte + i));
        }
    }

    read :: (bytes: [] u8, index: *int, value: *float) {
        assert(<< index + 4 <= bytes.count);

        << value = << cast(*float) *bytes[<< index];
        << index += 4;
    }

    write :: (bytes: *[..] u8, value: float) {
        byte: *u8 = xx *value;
        for i: 0..3 {
            array_add(bytes, << (byte + i));
        }
    }

    read :: (bytes: [] u8, index: *int, value: *float64) {
        assert(<< index + 8 <= bytes.count);

        << value = << cast(*float64) *bytes[<< index];
        << index += 8;
    }

    write :: (bytes: *[..] u8, value: float64) {
        byte: *u8 = xx *value;
        for i: 0..7 {
            array_add(bytes, << (byte + i));
        }
    }

    read :: (bytes: [] u8, index: *int, value: *string) {
        count: count_type;
        read(bytes, index, *count);
        #if unicode_strings {
            assert(<< index + count * 4 <= bytes.count);

            value.data = alloc(count * 4);
            memcpy(value.data, *bytes[<< index], count * 4);
            value.count = count; // im not sure about this

            << index += count * 4;
        } else {
            assert(<< index + count <= bytes.count);

            value.data = alloc(count);
            memcpy(value.data, *bytes[<< index], count);
            value.count = count;

            << index += count;
        }
    }

    write :: (bytes: *[..] u8, value: string) {
        write(bytes, cast(count_type) value.count);
        #if unicode_strings {
            for i: 0..value.count - 1 {
                array_add(bytes, 0);
                array_add(bytes, 0);
                array_add(bytes, 0);
                array_add(bytes, value[i]);
            }
        } else {
            for i: 0..value.count - 1 {
                array_add(bytes, value[i]);
            }
        }
    }

    read :: (bytes: [] u8, index: *int, value: *$T) {
        #if #run type_info(T).type == .ARRAY {
            read_array(bytes, index, value);
        } else #if #run type_info(T).type == .ENUM {
            read_enum(bytes, index, value);
        } else #if #run type_info(T).type == .STRUCT {
            read_struct(bytes, index, value);
        } else #if #run type_info(T).type == .VARIANT {
            read_variant(bytes, index, value);
        } else #if #run type_info(T).type == .POINTER {
            read_pointer(bytes, index, value);
        } else {
            #run () {
                print("Not supported type read. % %\n", type_info(T).type, T);
            }();
            #run assert(false && tprint("Not supported type read. %", type_info(T).type));
        }
    }

    write :: (bytes: *[..] u8, value: $T) {
        #if #run type_info(T).type == .ARRAY {
            write_array(bytes, value);
        } else #if #run type_info(T).type == .ENUM {
            write_enum(bytes, value);
        } else #if #run type_info(T).type == .STRUCT {
            write_struct(bytes, value);
        } else #if #run type_info(T).type == .VARIANT {
            write_variant(bytes, value);
        } else #if #run type_info(T).type == .POINTER {
            write_pointer(bytes, value);
        } else {
            #run () {
                print("Not supported type write. % %\n", type_info(T).type, T);
            }();
            #run assert(false && tprint("Not supported type write. %", type_info(T).type));
        }
    }

    read_array :: (bytes: [] u8, index: *int, array: *[$N] $T) {
        // TODO could just memcpy N and then increase index appropriately
        for i: 0..array.count - 1 {
            read(bytes, index, (cast(*T) array.data) + i);
        }
    }

    write_array :: (bytes: *[..] u8, array: [$N] $T) {
        for i: 0..N - 1 {
            write(bytes, array[i]);
        }
    }

    read_array :: (bytes: [] u8, index: *int, value: *[..] $T) {
        count: int;
        read(bytes, index, *count);
        array_resize(value, count);

        value.count = count;
        for i: 0..count - 1 {
            read(bytes, index, (cast(*T) value.data) + i);
        }
    }

    write_array :: (bytes: *[..] u8, array: [..] $T) {
        write(bytes, array.count);

        for i: 0..array.count - 1 {
            write(bytes, array[i]);
        }
    }

    read_array :: (bytes: [] u8, index: *int, value: *[] $T) {
        count: int;
        read(bytes, index, *count);
        << value = NewArray(count, T);

        value.count = count;
        for i: 0..count - 1 {
            read(bytes, index, (cast(*T) value.data) + i);
        }
    }

    write_array :: (bytes: *[..] u8, array: [] $T) {
        write(bytes, array.count);

        for i: 0..array.count - 1 {
            write(bytes, array[i]);
        }
    }

    read_enum :: (bytes: [] u8, index: *int, value: *$T) {
        get_constant_type :: ($bytes: int) -> Type {
            #if bytes == 1 {
                return u8;
            } else #if bytes == 2 {
                return u16;
            } else #if bytes == 4 {
                return u32;
            } else #if bytes == 8 {
                return u64;
            }

            assert(false);
        };

        enum_bytes :: #run type_info(T).runtime_size;
        ConstantType :: #run get_constant_type(enum_bytes);

        read(bytes, index, cast(*ConstantType) value);
    }

    write_enum :: (bytes: *[..] u8, value: $T) {
        get_constant_type :: ($bytes: int) -> Type {
            #if bytes == 1 {
                return u8;
            } else #if bytes == 2 {
                return u16;
            } else #if bytes == 4 {
                return u32;
            } else #if bytes == 8 {
                return u64;
            }

            assert(false);
        };

        enum_bytes :: #run type_info(T).runtime_size;
        ConstantType :: #run get_constant_type(enum_bytes);

        write(bytes, cast(ConstantType) value);
    }

    read_struct :: (bytes: [] u8, index: *int, value: *$T) {
        read_member :: ($member_name: string) #expand {
            {
                constant_member :: #run () -> bool {
                    // constant check
                    struct_info := cast(*Type_Info_Struct) type_info(T);
                    for member: struct_info.members {
                        if member.name == member_name {
                            return !!(member.flags & .CONSTANT);
                        }
                    }

                    return false;
                }();

                // if the byte offset has already been visited it means it's something weird like #place
                already_visited_byte_offset :: #run () -> bool {
                    visited_byte_offsets: [..] int;
                    struct_info := cast(*Type_Info_Struct) type_info(T);
                    for member: struct_info.members {
                        if member.name == member_name {
                            if member.offset_in_bytes < 0 {
                                return false;
                            }

                            return array_find(visited_byte_offsets, member.offset_in_bytes);
                        } else {
                            array_add(*visited_byte_offsets, member.offset_in_bytes);
                        }
                    }

                    return false;
                }();

                #if !already_visited_byte_offset {
                    #if constant_member {
                        struct_info := cast(*Type_Info_Struct) type_info(T);
                        for member: struct_info.members {
                            if member.name == member_name {
                                << index += member.type.runtime_size;
                                break;
                            }
                        }
                    } else {
                        // #run print("read %\n", tprint("member_value := *value.%;", member_name));
                        #insert #run tprint("member_value := *value.%;", member_name);
                        read(bytes, index, member_value);
                    }
                }
            }
        }

        expand_for :: (function_name: string, element_names: [] string) -> string {
            // TODO temp mem only
            sb: String_Builder;

            for i: 0..element_names.count - 1 {
                print_to_builder(*sb, "%(\"%\");\n", function_name, element_names[i]);
            }

            return builder_to_string(*sb);
        }

        get_member_names :: () -> [] string {
            #insert #run tprint("member_names: [%] string;", (cast(*Type_Info_Struct) type_info(T)).members.count);
            info := cast(*Type_Info_Struct) type_info(T);
            for i: 0..info.members.count - 1 {
                member_names[i] = info.members[i].name;
            }

            return member_names;
        }

        // if it panic crashes here it's because the appropriate type isn't handled
        #insert #run expand_for("read_member", #run get_member_names());
    }

    write_struct :: (bytes: *[..] u8, value: $T) {
        write_member :: ($member_name: string) #expand {
            {
                // if the byte offset has already been visited it means it's something weird like #place
                already_visited_byte_offset :: #run () -> bool {
                    visited_byte_offsets: [..] int;
                    struct_info := cast(*Type_Info_Struct) type_info(T);
                    for member: struct_info.members {
                        if member.name == member_name {
                            if member.offset_in_bytes < 0 {
                                return false;
                            }

                            return array_find(visited_byte_offsets, member.offset_in_bytes);
                        } else {
                            array_add(*visited_byte_offsets, member.offset_in_bytes);
                        }
                    }

                    return false;
                }();
                
                #if !already_visited_byte_offset {
                    #insert #run tprint("member_value := value.%;", member_name);
                    write(bytes, member_value);
                }
            }
        }

        expand_for :: (function_name: string, element_names: [] string) -> string {
            // TODO temp mem only
            sb: String_Builder;

            for i: 0..element_names.count - 1 {
                print_to_builder(*sb, "%(\"%\");\n", function_name, element_names[i]);
            }

            return builder_to_string(*sb);
        }

        get_member_names :: () -> [] string {
            #insert #run tprint("member_names: [%] string;", (cast(*Type_Info_Struct) type_info(T)).members.count);
            info := cast(*Type_Info_Struct) type_info(T);
            print("getting members of %\n", << info);
            for i: 0..info.members.count - 1 {
                member_names[i] = info.members[i].name;
            }

            return member_names;
        }

        // if it panic crashes here it's because the appropriate type isn't handled
        #insert #run expand_for("write_member", #run get_member_names());
    }

    read_variant :: (bytes: [] u8, index: *int, value: *$T) {
        ConstantType :: #run << (cast(*Type) (*(cast(*Type_Info_Variant) type_info(T)).variant_of));

        casted: *ConstantType = cast(*ConstantType) value;
        read(bytes, index, casted);
    }

    write_variant :: (bytes: *[..] u8, value: $T) {
        ConstantType :: #run << (cast(*Type) (*(cast(*Type_Info_Variant) type_info(T)).variant_of));

        casted: ConstantType = cast(ConstantType) value;
        write(bytes, casted);
    }

    read_pointer :: (bytes: [] u8, index: *int, value: *$T) {
        #run assert((cast(*Type_Info_Pointer) type_info(T)).relative_pointer_size == 0, "Cannot read a relative pointer.");

        ConstantType :: #run << (cast(*Type) (*(cast(*Type_Info_Pointer) type_info(T)).pointer_to));

        exists := << cast(*bool) *bytes[<< index];
        << index += 1;

        if !exists {
            << value = null;
        } else {
            allocated := New(ConstantType, false);
            << value = allocated;

            read(bytes, index, allocated);
        }
    }

    write_pointer :: (bytes: *[..] u8, value: $T) {
        #run assert((cast(*Type_Info_Pointer) type_info(T)).relative_pointer_size == 0, "Cannot write a relative pointer.");

        ConstantType :: #run << (cast(*Type) (*(cast(*Type_Info_Pointer) type_info(T)).pointer_to));

        if value == null {
            array_add(bytes, 0);
        } else {
            array_add(bytes, 1);
            write(bytes, << value);
        }
    }

    get_struct_type :: (bytes: [] u8, index: int, length: int, $types: [$N] Type) -> bool, Type {
        found, type := get_struct_type(bytes, index, types);
        if !found || size_of(type) != length {
            return false, bool;
        }

        return found, type;
    }

    // this function returns the struct type based on constant values defined inside the struct
    // to avoid weirdness they should be at the same byte offset so that dynamically written byte values can't overlap with constant written byte values values
    // constant structs are undefined behavior I think
    get_struct_type :: (bytes: [] u8, index: int, $types: [$N] Type) -> bool, Type {
        #insert #run tprint("comparison_bytes :: int.[%];\n", (types: [$N] Type) -> string {
            get_constant_byte_list :: (struct_info: *Type_Info_Struct) -> [..] int {
                byte_list: [..] int;
                dynamic_offset: int;

                for member: struct_info.members {
                    // only get constant members
                    if !(member.flags & .CONSTANT) {
                        dynamic_offset += member.type.runtime_size;
                        continue;
                    }

                    // constant_offset := member.offset_into_constant_storage;
                    constant_size := member.type.runtime_size;

                    for byte_offset: 0..constant_size - 1 {
                        byte_index := dynamic_offset + byte_offset;
                        array_add(*byte_list, byte_index);
                    }

                    dynamic_offset += member.type.runtime_size;
                }

                return byte_list;
            }

            fill_bytes := true;
            potential_bytes: [..] int;
            for type: types {
                info := cast(*Type_Info) type;
                assert(info.type == .STRUCT, "You can only compare structs.");

                byte_list := get_constant_byte_list(cast(*Type_Info_Struct) type);

                if fill_bytes {
                    fill_bytes = false;

                    for byte: byte_list {
                        array_add(*potential_bytes, byte);
                    }
                } else {
                    i := 0;
                    while i < potential_bytes.count {
                        // if this potential byte doesn't overlap with this structs constant bytes, remove it as a potential
                        if !array_find(byte_list, potential_bytes[i]) {
                            array_ordered_remove_by_index(*potential_bytes, i);
                        } else {
                            i += 1;
                        }
                    }
                    // for i: 0..potential_bytes.count - 1 {
                    // }
                }
            }

            assert(potential_bytes.count > 0, "You cannot compare these structs. They have no overlapping constant bytes.");

            sb: String_Builder;
            for i: 0..potential_bytes.count - 1 {
                append(*sb, tprint("%", potential_bytes[i]));
                if i < potential_bytes.count - 1 {
                    append(*sb, ", ");
                }
            }

            return builder_to_string(*sb);
        }(types));

        #insert #run tprint("comparison_values :: ([%] u8).[%];\n", comparison_bytes.count, (types: [$N] Type, comparison_bytes: [$M] int) -> string {
            get_constant_byte_data :: (struct_info: *Type_Info_Struct, comparison_bytes: [] int) -> [M] u8 {
                byte_list: [M] u8;
                dynamic_offset: int;

                constant_storage := struct_info.constant_storage_buffer;

                for member: struct_info.members {
                    // only get constant members
                    if !(member.flags & .CONSTANT) {
                        dynamic_offset += member.type.runtime_size;
                        continue;
                    }

                    constant_offset := member.offset_into_constant_storage;
                    constant_size := member.type.runtime_size;

                    for byte_offset: 0..constant_size - 1 {
                        byte_index := dynamic_offset + byte_offset;

                        for comparison_index: 0..comparison_bytes.count - 1 {
                            if byte_index == comparison_bytes[comparison_index] {
                                byte_list.data[comparison_index] = constant_storage[constant_offset + byte_offset];
                            }
                        }
                    }

                    dynamic_offset += member.type.runtime_size;
                }

                return byte_list;
            }

            sb: String_Builder;
            for i: 0..types.count - 1 {
                info := cast(*Type_Info) types[i];
                assert(info.type == .STRUCT, "You can only compare structs.");

                byte_list := get_constant_byte_data(cast(*Type_Info_Struct) types[i], comparison_bytes);
                append(*sb, ".[");
                for a: 0..byte_list.count - 1 {
                    append(*sb, tprint("%", byte_list[a]));

                    if a < byte_list.count - 1 {
                        append(*sb, ", ");
                    }
                }
                append(*sb, "]");

                if i < types.count - 1 {
                    append(*sb, ", ");
                }
            }

            return builder_to_string(*sb);
        }(types, comparison_bytes));

        #run (comparison_values: [$M][comparison_bytes.count] u8) {
            for i: 0..comparison_values.count - 1 {
                for a: 0..comparison_values.count - 1 {
                    if i == a {
                        continue;
                    }

                    same := true;
                    for b: 0..comparison_values[a].count - 1 {
                        if comparison_values[a] != comparison_values[b] {
                            same = false;
                            break;
                        }
                    }

                    assert(!same, tprint("You cannot compare two structs who share the same constant byte overlsap. % == %", i, a));
                }
            }
        }(comparison_values);

        // TODO if I care and have a ton of structs somehow like 1000+ you could dynamically generate if statements so that it checks 1 byte at a time, like with log complexity instead of linear
        #insert #run (comparison_bytes: [$M] int) -> string {
            sb: String_Builder;

            for i: 0..types.count - 1 {
                if i == 0 {
                    append(*sb, "if ");
                } else {
                    append(*sb, " else if ");
                }

                for byte_index: 0..comparison_bytes.count - 1 {
                    append(*sb, tprint("bytes[index + %] == %", comparison_bytes[byte_index], comparison_values[i][byte_index]));

                    if byte_index < comparison_bytes.count - 1 {
                        append(*sb, " && ");
                    }
                }

                append(*sb, " {\n");
                append(*sb, tprint("return true, types[%];\n", i));
                append(*sb, "}");
            }

            print("Generated code \n\n%\n\n", builder_to_string(*sb));

            return builder_to_string(*sb);
        }(comparison_bytes);

        return false, bool;
    }
}

#scope_file

#run assert(size_of(int) == 8);
#run assert(size_of(float) == 4);
#run assert(size_of(float64) == 8);

// expand_for :: (function_name: string, element_names: [] string) -> string {
//     // TODO temp mem only
//     sb: String_Builder;

//     for i: 0..element_names.count - 1 {
//         print_to_builder(*sb, "%(\"%\");\n", function_name, element_names[i]);
//     }

//     return builder_to_string(*sb);
// }

#import "Basic";
