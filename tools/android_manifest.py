"""Enable OS-managed GameActivity resizing in an existing binary Android XML.

Only modifies the existing typed boolean; does not rebuild resources or change
permissions, Java, native libraries, orientation, package or signing identity.
Unknown/malformed manifests fail rather than silently producing a broken APK.
"""
import struct

ANDROID = 'http://schemas.android.com/apk/res/android'
ACTIVITY = 'org.love2d.android.GameActivity'


def enable_game_resize(data):
    try:
        return _enable(data)
    except (struct.error, IndexError, UnicodeError) as error:
        raise ValueError('Malformed binary Android manifest') from error


def _enable(data):
    if len(data) < 8:
        raise ValueError('Missing binary Android XML header')
    kind, header, total = struct.unpack_from('<HHI', data)
    if kind != 3 or header != 8 or total != len(data):
        raise ValueError('Invalid binary Android XML size or type')
    result = bytearray(data)
    strings, matches = [], 0
    def u32(offset):
        return struct.unpack_from('<I', data, offset)[0]
    def length(offset, utf8):
        size, mask, shift = (1, 0x80, 8) if utf8 else (2, 0x8000, 16)
        value = data[offset] if utf8 else struct.unpack_from('<H', data, offset)[0]
        if value & mask:
            tail = data[offset + size] if utf8 else struct.unpack_from('<H', data, offset + size)[0]
            return ((value & (mask - 1)) << shift) + tail, offset + 2 * size
        return value, offset + size
    def string(index):
        if index == 0xffffffff:
            return None
        if index >= len(strings):
            raise ValueError('Invalid Android XML string index')
        return strings[index]
    position = 8
    while position < total:
        kind, header, size = struct.unpack_from('<HHI', data, position)
        end = position + size
        if header < 8 or size < header or end > total:
            raise ValueError('Invalid Android XML chunk')
        if kind == 1:  # RES_STRING_POOL_TYPE
            if strings or header < 28:
                raise ValueError('Invalid Android XML string pool')
            count, flags = u32(position + 8), u32(position + 16)
            if position + header + count * 4 > end:
                raise ValueError('Invalid Android XML string offsets')
            start = position + u32(position + 20)
            utf8 = bool(flags & 0x100)
            for index in range(count):
                offset = start + u32(position + header + index * 4)
                if utf8:
                    _, offset = length(offset, True)
                count_bytes, offset = length(offset, utf8)
                stop = offset + count_bytes * (1 if utf8 else 2)
                if not start <= offset <= stop <= end:
                    raise ValueError('Invalid Android XML string length')
                strings.append(data[offset:stop].decode('utf-8' if utf8 else 'utf-16le'))
        elif kind == 0x102:  # RES_XML_START_ELEMENT_TYPE
            if header < 16 or position + header + 20 > end:
                raise ValueError('Invalid Android XML element')
            element = string(u32(position + header + 4))
            start, stride, count = struct.unpack_from('<HHH', data, position + header + 8)
            base = position + header + start
            if start < 20 or stride < 20 or base + count * stride > end:
                raise ValueError('Invalid Android XML attributes')
            attrs = {}
            for index in range(count):
                offset = base + index * stride
                namespace, name, raw = struct.unpack_from('<III', data, offset)
                value_type, value = data[offset + 15], u32(offset + 16)
                value = string(value) if value_type == 3 else value
                attrs[(string(namespace), string(name))] = (offset, value_type, value)
            name = attrs.get((ANDROID, 'name'))
            if element == 'activity' and name and name[2] == ACTIVITY:
                attribute = attrs.get((ANDROID, 'resizeableActivity'))
                if not attribute or attribute[1] != 0x12:
                    raise ValueError('GameActivity must have an existing resizeableActivity boolean')
                offset = attribute[0]
                struct.pack_into('<I', result, offset + 8, 0xffffffff)  # no conflicting raw string
                struct.pack_into('<I', result, offset + 16, 0xffffffff)
                matches += 1
        position = end
    if matches != 1:
        raise ValueError('Expected exactly one org.love2d.android.GameActivity')
    return bytes(result)
