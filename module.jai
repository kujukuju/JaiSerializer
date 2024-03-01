
#module_parameters(count_type: Type = int, unicode_strings: bool = false, write_constants: bool = false);

// #run assert(!reuse_memory || (count_type == int && !unicode_strings && !write_constants), "You cannot change any of the serializer settings if reuse memory is enabled.");

// TODO the current problem is serializer_read always memcpys for reuse mode, even though it should only do it on the first call

// what makes this so complicated to read, is typically the reuse serializer will write the raw bytes of an object or array into the bytes array/memory
// and then it will update the value data pointer to point back to that newly written data, so if it then changes something like value.data (the data pointer of an array)
// the data change will be reflected in the raw byte array

serializer_read :: (bytes: [] u8, value: *$T, $reuse_memory: bool = false, $loc := #caller_location) {
    serializer_read(bytes, value, 0, reuse_memory);
}

serializer_read :: (bytes: [] u8, value: *$T, offset: int, $reuse_memory: bool = false, $loc := #caller_location) -> int {
    // info :: #run type_info(T);
    info_type :: #run type_info(T).type;
    t_size :: #run size_of(T);
    pod :: #run is_pod(T);

    #if reuse_memory {
        assert(offset == 0, "You cannot currently use reuse_memory mode with an offset.");
        view: [] u8;
        view.data = bytes.data + offset;
        view.count = bytes.count - offset;
    }

    #if reuse_memory || pod {
        memcpy(value, bytes.data + offset, t_size);
        offset += t_size;
    }

    #if !pod {
        #if info_type == .STRING {
            #if reuse_memory {
                inline read_string_reuse(view, value);
            } else {
                offset = inline read_string(bytes, value, offset);
            }
        } else #if info_type == .POINTER {
            #if reuse_memory {
                inline read_pointer_reuse(view, value);
            } else {
                offset = inline read_pointer(bytes, value, offset);
            }
        } else #if info_type == .STRUCT {
            #if reuse_memory {
                inline read_struct_reuse(view, value);
            } else {
                offset = inline read_struct(bytes, value, offset);
            }
        } else #if info_type == .ARRAY {
            #if reuse_memory {
                inline read_array_reuse(view, value);
            } else {
                offset = inline read_array(bytes, value, offset);
            }
        } else #if info_type == .VOID {

        } else {
            #run print("Unhandled serialization type. %\n", T);
            #run assert(false, tprint("Unhandled serialization type. %\n", T));
        }
    }

    return offset;
}

serializer_write :: (bytes: *[..] u8, value: $T, $reuse_memory: bool = false) {
    // info :: #run type_info(T);
    info_type :: #run type_info(T).type;
    t_size :: #run size_of(T);
    pod :: #run is_pod(T);

    #if pod {
        array_reserve(bytes, bytes.count + t_size);
    } else {
        #if reuse_memory {
            allocate_size := get_write_size_reuse(value);
        } else {
            allocate_size := get_write_size(value);
        }
        array_reserve(bytes, bytes.count + allocate_size);
    }

    #if reuse_memory || pod {
        memcpy(bytes.data + bytes.count, *value, t_size);
        bytes.count += t_size;
    }
    
    #if !pod {
        #if info_type == .STRING {
            #if reuse_memory {
                inline write_string_reuse(bytes, cast(*T) (bytes.data + bytes.count - t_size));
            } else {
                inline write_string(bytes, value);
            }
        } else #if info_type == .POINTER {
            #if reuse_memory {
                inline write_pointer_reuse(bytes, cast(*T) (bytes.data + bytes.count - t_size));
            } else {
                inline write_pointer(bytes, value);
            }
        } else #if info_type == .STRUCT {
            #if reuse_memory {
                inline write_struct_reuse(bytes, cast(*T) (bytes.data + bytes.count - t_size));
            } else {
                inline write_struct(bytes, value);
            }
        } else #if info_type == .ARRAY {
            #if reuse_memory {
                inline write_array_reuse(bytes, cast(*T) (bytes.data + bytes.count - t_size));
            } else {
                inline write_array(bytes, value);
            }
        } else #if info_type == .VOID {

        } else {
            #run print("Unhandled serialization type. %\n", T);
            #run assert(false, "Unhandled serialization type.");
        }
    }

    assert(bytes.count == bytes.allocated, tprint("Allocated and count size must match. % = %\n", bytes.count, bytes.allocated));
}

// this function errs on the side of caution, some types aren't even considered
is_pod :: (T: Type) -> bool {
    info := cast(*Type_Info) T;

    if info.type == {
        case .INTEGER;
            return true;

        case .FLOAT;
            return true;

        case .BOOL;
            return true;

        case .ENUM;
            return true;

        case .STRUCT;
            struct_info := cast(*Type_Info_Struct) info;

            pod := true;
            for member: struct_info.members {
                // could a constant member be non-constant?
                is_pod_member := (member.flags & .CONSTANT) || is_pod(get_type(member.type));
                pod = pod && is_pod_member;
            }
            return pod;

        case .ARRAY;
            array_info := cast(*Type_Info_Array) info;

            pod := true;
            pod = pod && array_info.array_type == .FIXED;
            pod = pod && is_pod(get_type(array_info.element_type));
            return pod;

        case;
            return false;
    }
}

#scope_file

serializer_read_reuse :: (bytes: [] u8, value: *$T) {
    // info :: #run type_info(T);
    info_type :: #run type_info(T).type;
    t_size :: #run size_of(T);
    pod :: #run is_pod(T);

    #if !pod {
        #if info_type == .STRING {
            inline read_string_reuse(bytes, value);
        } else #if info_type == .POINTER {
            inline read_pointer_reuse(bytes, value);
        } else #if info_type == .STRUCT {
            inline read_struct_reuse(bytes, value);
        } else #if info_type == .ARRAY {
            inline read_array_reuse(bytes, value);
        } else #if info_type == .VOID {

        } else {
            #run print("Unhandled serialization type. %\n", T);
            #run assert(false, "Unhandled serialization type.");
        }
    }
}

read_string_reuse :: (bytes: [] u8, value: *$T) {
    string_size :: #run size_of(T);

    value.data = bytes.data + cast(int) value.data;
    // (cast(*u8) value.data) += bytes.data;
}

read_string :: (bytes: [] u8, value: *$T, offset: int) -> int {
    count_size :: #run size_of(count_type);

    string_count := (cast(*count_type) (bytes.data + offset)).*;
    #if unicode_strings {
        allocate_size := string_count * 4;
    } else {
        allocate_size := string_count;
    }

    value.data = alloc(allocate_size);
    value.count = string_count;

    memcpy(value.data, bytes.data + offset + count_size, allocate_size);

    return offset + count_size + allocate_size;
}

read_pointer_reuse :: (bytes: [] u8, value: *$T) {
    value.* = cast(T) (cast(*u8) value.* + cast(int) bytes.data);

    if value.* {
        serializer_read_reuse(bytes, value.*);
    }
}

read_pointer :: (bytes: [] u8, value: *$T, offset: int) -> int {
    bool_size :: #run size_of(bool);
    pointer_type :: #run get_type(type_info(T).pointer_to);
    pointer_size :: #run size_of(pointer_type);

    exists := (cast(*bool) bytes.data + offset).*;
    if !exists {
        value.* = null;
        return offset + bool_size;
    } else {
        value.* = New(pointer_type);
        return serializer_read(bytes, value.*, offset + bool_size);
    }
}

read_struct_reuse :: (bytes: [] u8, value: *$T) {
    #insert #run () -> string {
        info := cast(*Type_Info_Struct) type_info(T);

        builder: String_Builder;

        for member: info.members {
            member_info := member.type;
            member_type := get_type(member_info);

            if should_skip_member(member) {
                continue;
            }

            if is_pod(member_type) {
                continue;
            }

            // TODO check place & union

            if member_info.type == .STRING {
                append(*builder, tprint("inline read_string_reuse(bytes, *value.%);", member.name));
            } else if member_info.type == .POINTER {
                append(*builder, tprint("inline read_pointer_reuse(bytes, *value.%);", member.name));
            } else if member_info.type == .STRUCT {
                append(*builder, tprint("inline read_struct_reuse(bytes, *value.%);", member.name));
            } else if member_info.type == .ARRAY {
                append(*builder, tprint("inline read_array_reuse(bytes, *value.%);", member.name));
            } else {
                print("Unhandled serialization type. % %\n", member_info.type, T);
                assert(false, tprint("Unhandled serialization type. % %\n", member_info.type, T));
            }
        }

        return builder_to_string(*builder);
    }();
}

read_struct :: (bytes: [] u8, value: *$T, offset: int) -> int {
    // it only gets to this method if there is at least some non-pod chunk
    #insert #run () -> string {
        info := cast(*Type_Info_Struct) type_info(T);

        builder: String_Builder;

        visited_byte_offsets: [..] int;
        visited_byte_offsets.allocator = temp;

        for member: info.members {
            member_info := member.type;
            member_type := get_type(member_info);

            if should_skip_member(member) {
                continue;
            }

            if array_find(visited_byte_offsets, member.offset_in_bytes) {
                continue;
            }
            array_add(*visited_byte_offsets, member.offset_in_bytes);

            // TODO check place & union

            // TODO continue checking for pod members and memcpy them all at once
            if is_pod(member_type) {
                t_size := member_info.runtime_size;

                append(*builder, tprint("memcpy(*value.%, bytes.data + offset, %);", member.name, t_size));
                append(*builder, tprint("offset += %;", t_size));
            } else if member_info.type == .STRING {
                append(*builder, tprint("offset = inline read_string(bytes, *value.%, offset);", member.name));
            } else if member_info.type == .POINTER {
                append(*builder, tprint("offset = inline read_pointer(bytes, *value.%, offset);", member.name));
            } else if member_info.type == .STRUCT {
                append(*builder, tprint("offset = inline read_struct(bytes, *value.%, offset);", member.name));
            } else if member_info.type == .ARRAY {
                append(*builder, tprint("offset = inline read_array(bytes, *value.%, offset);", member.name));
            } else {
                print("Unhandled serialization type. %\n", T);
                assert(false, "Unhandled serialization type.");
            }
        }

        return builder_to_string(*builder);
    }();

    return offset;
}

read_array_reuse :: (bytes: [] u8, value: *$T) {
    // info :: #run cast(*Type_Info_Array) type_info(T);
    // element_info :: #run (cast(*Type_Info_Array) type_info(T)).element_type;
    info_array_type :: #run (cast(*Type_Info_Array) type_info(T)).array_type;
    element_info_type :: #run (cast(*Type_Info_Array) type_info(T)).element_type.type;
    element_type :: #run get_type((cast(*Type_Info_Array) type_info(T)).element_type);
    element_size :: #run size_of(element_type);

    #if info_array_type == .FIXED {
        // copy memory basically, unfortunately
        // value.* = (cast(*T) (bytes.data + cast(int) value.data)).*;
    } else {
        // move data pointer
        value.data = cast(*element_type) (cast(int) bytes.data + cast(int) value.data);
    }

    #if #run info_array_type == .RESIZABLE {
        value.allocator = reuse_allocator;
    }

    // if this array data isn't pod we have to go through 1 by 1
    #if #run !is_pod(element_type) {
        for i: 0..value.count - 1 {
            element_pointer: *element_type = value.data + i;

            #if element_info_type == .STRING {
                inline read_string_reuse(bytes, element_pointer);
            } else #if element_info_type == .POINTER {
                inline read_pointer_reuse(bytes, element_pointer);
            } else #if element_info_type == .STRUCT {
                inline read_struct_reuse(bytes, element_pointer);
            } else #if element_info_type == .ARRAY {
                inline read_array_reuse(bytes, element_pointer);
            } else #if element_info_type == .VOID {

            } else {
                #run print("Unhandled serialization type. %\n", element_type);
                #run assert(false, "Unhandled serialization type.");
            }
        }
    }
}

read_array :: (bytes: [] u8, value: *$T, offset: int) -> int {
    // info :: #run cast(*Type_Info_Array) type_info(T);
    // element_info :: #run info.element_type;
    element_info_type :: #run (cast(*Type_Info_Array) type_info(T)).element_type.type;
    element_type :: #run get_type((cast(*Type_Info_Array) type_info(T)).element_type);
    element_size :: #run size_of(element_type);

    #if #run (cast(*Type_Info_Array) type_info(T)).array_type != .FIXED {
        count_size :: #run size_of(count_type);
        count: count_type;
        memcpy(*count, bytes.data + offset, count_size);
        array_resize(value, count);
        offset += count_size;
    }

    #if #run is_pod(element_type) {
        allocate_size := value.count * element_size;

        memcpy(value.data, bytes.data + offset, allocate_size);
        offset += allocate_size;
    } else {
        for i: 0..value.count - 1 {
            element_pointer := value.data + i;

            #if element_info_type == .STRING {
                offset = inline read_string(bytes, element_pointer, offset);
            } else #if element_info_type == .POINTER {
                offset = inline read_pointer(bytes, element_pointer, offset);
            } else #if element_info_type == .STRUCT {
                offset = inline read_struct(bytes, element_pointer, offset);
            } else #if element_info_type == .ARRAY {
                offset = inline read_array(bytes, element_pointer, offset);
            } else #if element_info_type == .VOID {

            } else {
                #run print("Unhandled serialization type. %\n", element_type);
                #run assert(false, "Unhandled serialization type.");
            }
        }
    }

    return offset;
}

write_string_reuse :: (bytes: *[..] u8, value: *$T) {
    memcpy(bytes.data + bytes.count, value.data, value.count);

    value.data = cast(*u8) bytes.count;
    bytes.count += value.count;
}

write_string :: (bytes: *[..] u8, value: $T) {
    count_size :: #run size_of(count_type);
    count := cast(count_type) value.count;

    #if unicode_strings {
        allocate_size := value.count * 4;
    } else {
        allocate_size := value.count;
    }

    memcpy(bytes.data + bytes.count, *count, count_size);
    memcpy(bytes.data + bytes.count + count_size, value.data, allocate_size);
    bytes.count += count_size + allocate_size;
}

write_pointer_reuse :: (bytes: *[..] u8, value: *$T) {
    // info :: #run cast(*Type_Info_Pointer) type_info(T);
    // element_info :: #run (cast(*Type_Info_Pointer) type_info(T)).pointer_to;
    element_info_type :: #run (cast(*Type_Info_Pointer) type_info(T)).pointer_to.type;
    element_type :: #run get_type((cast(*Type_Info_Pointer) type_info(T)).pointer_to);
    element_size :: #run size_of(element_type);

    if value.* {
        memcpy(bytes.data + bytes.count, value.*, element_size);

        value.* = cast(T) bytes.count;
        bytes.count += element_size;

        #if #run !is_pod(element_type) {
            element_pointer := cast(T) (bytes.data + bytes.count - element_size);

            #if element_info_type == .STRING {
                inline write_string_reuse(bytes, element_pointer);
            } else #if element_info_type == .POINTER {
                inline write_pointer_reuse(bytes, element_pointer);
            } else #if element_info_type == .STRUCT {
                inline write_struct_reuse(bytes, element_pointer);
            } else #if element_info_type == .ARRAY {
                inline write_array_reuse(bytes, element_pointer);
            } else #if element_info_type == .VOID {

            } else {
                #run print("Unhandled serialization type. %\n", element_type);
                #run assert(false, "Unhandled serialization type.");
            }
        }
    }
}

write_pointer :: (bytes: *[..] u8, value: $T) {
    // info :: #run cast(*Type_Info_Pointer) type_info(T);
    // element_info :: #run (cast(*Type_Info_Pointer) type_info(T)).pointer_to;
    bool_size :: #run size_of(bool);
    element_info_type :: #run (cast(*Type_Info_Pointer) type_info(T)).pointer_to.type;
    element_type :: #run get_type((cast(*Type_Info_Pointer) type_info(T)).pointer_to);
    element_size :: #run size_of(element_type);

    if value {
        exists := true;
        memcpy(bytes.data + bytes.count, *exists, bool_size);
        bytes.count += bool_size;

        #if #run is_pod(element_type) {
            memcpy(bytes.data + bytes.count, value, element_size);
            bytes.count += element_size;
        } else #if element_info_type == .STRING {
            inline write_string(bytes, value.*);
        } else #if element_info_type == .POINTER {
            inline write_pointer(bytes, value.*);
        } else #if element_info_type == .STRUCT {
            inline write_struct(bytes, value.*);
        } else #if element_info_type == .ARRAY {
            inline write_array(bytes, value.*);
        } else #if element_info_type == .VOID {

        } else {
            #run print("Unhandled serialization type. % %\n", element_type, element_info_type);
            #run assert(false, tprint("Unhandled serialization type. % %\n", element_type, element_info_type));
        }
    } else {
        exists := false;
        memcpy(bytes.data + bytes.count, *exists, bool_size);
        bytes.count += bool_size;
    }
}

write_struct_reuse :: (bytes: *[..] u8, value: *$T) {
    #insert #run () -> string {
        info := cast(*Type_Info_Struct) type_info(T);

        builder: String_Builder;

        for member: info.members {
            member_info := member.type;
            member_type := get_type(member_info);

            if should_skip_member(member) {
                continue;
            }
            
            if is_pod(member_type) {
                continue;
            }

            // TODO check place & union

            if member_info.type == .STRING {
                append(*builder, tprint("inline write_string_reuse(bytes, *value.%);", member.name));
            } else if member_info.type == .POINTER {
                append(*builder, tprint("inline write_pointer_reuse(bytes, *value.%);", member.name));
            } else if member_info.type == .STRUCT {
                append(*builder, tprint("inline write_struct_reuse(bytes, *value.%);", member.name));
            } else if member_info.type == .ARRAY {
                append(*builder, tprint("inline write_array_reuse(bytes, *value.%);", member.name));
            } else {
                print("Unhandled serialization type. %\n", T);
                assert(false, "Unhandled serialization type.");
            }
        }

        return builder_to_string(*builder);
    }();
}

write_struct :: (bytes: *[..] u8, value: $T) {
    #insert #run () -> string {
        info := cast(*Type_Info_Struct) type_info(T);

        builder: String_Builder;

        visited_byte_offsets: [..] int;
        visited_byte_offsets.allocator = temp;

        for member: info.members {
            member_info := member.type;
            member_type := get_type(member_info);

            if should_skip_member(member) {
                continue;
            }

            if array_find(visited_byte_offsets, member.offset_in_bytes) {
                continue;
            }
            array_add(*visited_byte_offsets, member.offset_in_bytes);

            // TODO check place & union

            // TODO continue checking for pod members and memcpy them all at once
            if is_pod(member_type) {
                t_size := member_info.runtime_size;

                append(*builder, tprint("memcpy(bytes.data + bytes.count, *value.%, %);", member.name, t_size));
                append(*builder, tprint("bytes.count += %;", t_size));
            } else if member_info.type == .STRING {
                append(*builder, tprint("inline write_string(bytes, value.%);", member.name));
            } else if member_info.type == .POINTER {
                append(*builder, tprint("inline write_pointer(bytes, value.%);", member.name));
            } else if member_info.type == .STRUCT {
                append(*builder, tprint("inline write_struct(bytes, value.%);", member.name));
            } else if member_info.type == .ARRAY {
                append(*builder, tprint("inline write_array(bytes, value.%);", member.name));
            } else {
                print("Unhandled serialization type. % %\n", member_info.type, T);
                assert(false, "Unhandled serialization type.");
            }
        }

        return builder_to_string(*builder);
    }();
}

write_array_reuse :: (bytes: *[..] u8, value: *$T) {
    element_info_type :: #run (cast(*Type_Info_Array) type_info(T)).element_type.type;
    array_type :: #run (cast(*Type_Info_Array) type_info(T)).array_type;
    element_type :: #run get_type((cast(*Type_Info_Array) type_info(T)).element_type);
    element_size :: #run size_of(element_type);

    allocate_bytes := value.count * element_size;
    memcpy(bytes.data + bytes.count, value.data, allocate_bytes);

    value.data = cast(*element_type) bytes.count;
        bytes.count += allocate_bytes;

    // if this array data isn't pod we have to go through 1 by 1
    #if #run !is_pod(element_type) {
        start_pointer := cast(*element_type) (bytes.data + (cast(int) value.data));
        for i: 0..value.count - 1 {
            element_pointer: *element_type = start_pointer + i;

            #if #run element_info_type == .STRING {
                inline write_string_reuse(bytes, element_pointer);
            } else #if #run element_info_type == .POINTER {
                inline write_pointer_reuse(bytes, element_pointer);
            } else #if #run element_info_type == .STRUCT {
                inline write_struct_reuse(bytes, element_pointer);
            } else #if #run element_info_type == .ARRAY {
                inline write_array_reuse(bytes, element_pointer);
            } else #if #run element_info_type == .VOID {

            } else {
                #run print("Unhandled serialization type. %\n", element_type);
                #run assert(false, "Unhandled serialization type.");
            }
        }
    }
}

write_array :: (bytes: *[..] u8, value: $T) {
    // info :: #run cast(*Type_Info_Array) type_info(T);
    // element_info :: #run (cast(*Type_Info_Array) type_info(T)).element_type;
    element_info_type :: #run (cast(*Type_Info_Array) type_info(T)).element_type.type;
    element_type :: #run get_type((cast(*Type_Info_Array) type_info(T)).element_type);
    element_size :: #run size_of(element_type);

    count_size :: #run size_of(count_type);
    count := cast(count_type) value.count;

    #if #run is_pod(element_type) {
        allocate_size := value.count * element_size;

        memcpy(bytes.data + bytes.count, *count, count_size);
        memcpy(bytes.data + bytes.count + count_size, value.data, allocate_size);
        bytes.count += count_size + allocate_size;
    } else {
        if (cast(*Type_Info_Array) type_info(T)).array_type != .FIXED {
            memcpy(bytes.data + bytes.count, *count, count_size);
            bytes.count += count_size;
        }

        for element: value {
            #if #run element_info_type == .STRING {
                inline write_string(bytes, element);
            } else #if #run element_info_type == .POINTER {
                inline write_pointer(bytes, element);
            } else #if #run element_info_type == .STRUCT {
                inline write_struct(bytes, element);
            } else #if #run element_info_type == .ARRAY {
                inline write_array(bytes, element);
            } else #if #run element_info_type == .VOID {

            } else {
                #run print("Unhandled serialization type. %\n", element_type);
                #run assert(false, "Unhandled serialization type.");
            }
        }
    }
}

should_skip_member :: (member: Type_Info_Struct_Member) -> bool {
    member_info := member.type;
    member_type := get_type(member_info);

    skip := !!(member.flags & .CONSTANT);
    skip = skip || (member.flags & .USING && !member.name);
    skip = skip || (member_info.type == .VOID || member_info.type == .PROCEDURE);
    for note: member.notes {
        skip = skip || equal_nocase(note, "serializer(skip)");
    }

    return skip;
}

get_type :: (info: *Type_Info) -> Type {
    return (cast(*Type) *info).*;
}

get_write_size :: (value: $T) -> int {
    // info :: #run type_info(T);
    info_type :: #run type_info(T).type;

    #if #run is_pod(T) {
        return size_of(T);
    } else #if info_type == .STRING {
        return size_of(count_type) + value.count;
    } else #if info_type == .POINTER {
        if value {
            return size_of(bool) + get_write_size(value.*);
        } else {
            return size_of(bool);
        }
    } else #if info_type == .STRUCT {
        #insert #run () -> string {
            info := type_info(T);
            struct_info := cast(*Type_Info_Struct) info;

            builder: String_Builder;
            written: bool;

            visited_byte_offsets: [..] int;
            for member: struct_info.members {
                if should_skip_member(member) {
                    continue;
                }

                if array_find(visited_byte_offsets, member.offset_in_bytes) {
                    continue;
                }
                array_add(*visited_byte_offsets, member.offset_in_bytes);

                if !written {
                    written = true;
                    append(*builder, tprint("return get_write_size(value.%)", member.name));
                } else {
                    append(*builder, tprint(" + get_write_size(value.%)", member.name));
                }
            }

            append(*builder, ";");

            return builder_to_string(*builder);
        }();
    } else #if info_type == .ARRAY {
        // array_info :: #run cast(*Type_Info_Array) info;
        array_info_array_type :: #run (cast(*Type_Info_Array) type_info(T)).array_type;
        // element_info :: #run (cast(*Type_Info_Array) info).element_type;
        element_type :: #run get_type((cast(*Type_Info_Array) type_info(T)).element_type);
        element_size :: #run size_of(element_type);
    
        #if #run is_pod(element_type) {
            return size_of(count_type) + value.count * element_size;
        } else #if #run array_info_array_type == .FIXED {
            total_size := 0;
            for element: value {
                total_size += get_write_size(element);
            }
            return total_size;
        } else {
            total_size := size_of(count_type);
            for element: value {
                total_size += get_write_size(element);
            }
            return total_size;
        }
    } else #if info_type == .VOID {
        return 0;
    } else {
        #run print("Unhandled serialization type. % %\n", info_type, element_type);
        #run assert(false, tprint("Unhandled serialization type. % %\n", info_type, element_type));
    }
}

get_write_size_reuse :: (value: $T) -> int {
    #if #run is_pod(T) {
        return size_of(T);
    } else {
        return size_of(T) + get_data_write_size_reuse(value);
    }
}

// this is just the allocated size of memory
get_data_write_size_reuse :: (value: $T) -> int {
    // info :: #run type_info(T);
    info_type :: #run type_info(T).type;

    #if #run is_pod(T) {
        return 0;
    } else #if info_type == .STRING {
        return value.count;
    } else #if info_type == .POINTER {
        return get_write_size_reuse(value.*);
    } else #if info_type == .STRUCT {
        #insert #run () -> string {
            info := type_info(T);
            struct_info := cast(*Type_Info_Struct) info;

            builder: String_Builder;
            written: bool;

            for member: struct_info.members {
                member_info := member.type;
                member_type := get_type(member_info);
                
                if should_skip_member(member) {
                    continue;
                }
                
                if is_pod(member_type) {
                    continue;
                }

                if !written {
                    written = true;
                    append(*builder, tprint("return get_data_write_size_reuse(value.%)", member.name));
                } else {
                    append(*builder, tprint(" + get_data_write_size_reuse(value.%)", member.name));
                }
            }

            append(*builder, ";");

            return builder_to_string(*builder);
        }();
    } else #if info_type == .ARRAY {
        array_type :: #run (cast(*Type_Info_Array) type_info(T)).array_type;
        element_type :: #run get_type((cast(*Type_Info_Array) type_info(T)).element_type);
    
        #if #run is_pod(element_type) {
            return value.count * size_of(element_type);
        } else #if array_type == .FIXED {
            total_size := 0;
            for element: value {
                total_size += get_data_write_size_reuse(element);
            }
            return total_size;
        } else {
            total_size := 0;
            for element: value {
                total_size += get_write_size_reuse(element);
            }
            return total_size;
        }
    } else #if info_type == .VOID {
        return 0;
    } else {
        #run print("Unhandled serialization type. % %\n", info_type, element_type);
        #run assert(false, tprint("Unhandled serialization type. % %\n", info_type, element_type));
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

reuse_allocator_proc :: (mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void {
    assert(false, "You cannot allocate into an array that was deserialized with reuse_memory mode enabled.");
    return null;
}

reuse_allocator :: Allocator.{reuse_allocator_proc, null};








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
        assert(index.* + 4 <= bytes.count);

        value.* = (cast(*float) *bytes[<< index]).*;
        index.* += 4;
    }

    write :: (bytes: *[..] u8, value: float) {
        byte: *u8 = cast(*u8) *value;
        for i: 0..3 {
            array_add(bytes, (byte + i).*);
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
                        // #insert #run tprint("print(\"crashing at %\\n\");", member_name);
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
        // I think relative pointers were removed?
        // #run assert((cast(*Type_Info_Pointer) type_info(T)).relative_pointer_size == 0, "Cannot read a relative pointer.");

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
        // #run assert((cast(*Type_Info_Pointer) type_info(T)).relative_pointer_size == 0, "Cannot write a relative pointer.");

        ConstantType :: #run << (cast(*Type) (*(cast(*Type_Info_Pointer) type_info(T)).pointer_to));

        if value == null {
            array_add(bytes, 0);
        } else {
            array_add(bytes, 1);
            write(bytes, << value);
        }
    }
}

#run {
    assert(size_of(int) == 8);
    assert(size_of(float) == 4);
    assert(size_of(float64) == 8);
};
// #run assert(size_of(int) == 8);
// #run assert(size_of(float) == 4);
// #run assert(size_of(float64) == 8);

#import "Basic";
#import "String";
