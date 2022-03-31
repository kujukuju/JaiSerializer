## Jai Serializer

Serializes structs and data based on the member variables.

Works with constant values. Writes constants into the byte stream, and skips over them when reading from the byte stream. Probably will add a flag in the future to skip writing completely.

Works with directives like #place. Ignores member variables in byte locations that have already been visited.