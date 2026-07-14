import os
import re

COLOR_MAP = {
    '.': [255, 255, 255],
    '#': [40, 44, 52],
    'w': [240, 240, 245],
    'd': [108, 116, 128],
    'b': [80, 150, 240],
    'c': [80, 200, 220],
    'g': [80, 200, 120],
    'y': [240, 180, 50],
    'r': [220, 80, 80],
    'o': [255, 128, 0],
    'p': [180, 100, 220],
}

BASE_ICON = [
    "........................",
    "........................",
    ".........######.........",
    ".......##cccccc##.......",
    ".....##cccccccccc##.....",
    "....#cccccccccccccc#....",
    "....#cwwwwwwwwwwwwc#....",
    "....#cddddddddddddc#....",
    "....#cwwwwwwwwwwwwc#....",
    "....#cwwwwwwwwwwwwc#....",
    "....#cddddddddddddc#....",
    "....#cwwwwwwwwwwwwc#....",
    "....#cwwwwwwwwwwwwc#....",
    "....#cddddddddddddc#....",
    "....#cwwwwwwwwwwwwc#....",
    ".....#wwwwwwwwwwww#.....",
    "......##wwwwwwww##......",
    ".........######.........",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
]

BADGES = {
    'aidbase': (
        [
            "..gg..",
            ".g..g.",
            "g.yyg.",
            "g.yyg.",
            ".g..g.",
            "..gg..",
        ],
        9,
        3,
    ),
    'aidb_postgresql_dictionary': (
        [
            "..pp..",
            ".pppp.",
            "ppwwpp",
            "ppwwpp",
            ".pppp.",
            "..pp..",
        ],
        15,
        3,
    ),
    'aidb_mysql_dictionary': (
        [
            "..bb..",
            ".bbbo.",
            "bbboo.",
            ".bbbo.",
            "..bb..",
            "......",
        ],
        15,
        3,
    ),
    'aidb_sqlite_dictionary': (
        [
            ".dddd.",
            "dwwwwd",
            "dddddd",
            "dwwwwd",
            ".dddd.",
            "......",
        ],
        15,
        3,
    ),
    'aidb_firebird_dictionary': (
        [
            "..r...",
            ".rrr..",
            "rrorr.",
            "rrooo.",
            ".rrr..",
            "..y...",
        ],
        15,
        3,
    ),
    'aidb_sqlserver_dictionary': (
        [
            "rrrrrr",
            "rwwwwr",
            "rrrrrr",
            "rwwwwr",
            "rrrrrr",
            "......",
        ],
        15,
        3,
    ),
    'aidb_oracle_dictionary': (
        [
            "..rr..",
            ".r..r.",
            "r....r",
            "r....r",
            ".r..r.",
            "..rr..",
        ],
        15,
        3,
    ),
}

UNIT_FILES = {
    'aidbase': 'aidbase.pas',
    'aidb_postgresql_dictionary': 'aidb_postgresql_dictionary.pas',
    'aidb_mysql_dictionary': 'aidb_mysql_dictionary.pas',
    'aidb_sqlite_dictionary': 'aidb_sqlite_dictionary.pas',
    'aidb_firebird_dictionary': 'aidb_firebird_dictionary.pas',
    'aidb_sqlserver_dictionary': 'aidb_sqlserver_dictionary.pas',
    'aidb_oracle_dictionary': 'aidb_oracle_dictionary.pas',
}

# Lazarus resolves a component palette icon by the registered component class
# name, not by its unit or source filename. Keep this mapping explicit because
# several units use longer provider-specific filenames.
RESOURCE_NAMES = {
    'aidbase': 'TAIDBase',
    'aidb_postgresql_dictionary': 'TAIPostgreSQLDictionary',
    'aidb_mysql_dictionary': 'TAIMySQLDictionary',
    'aidb_sqlite_dictionary': 'TAISQLiteDictionary',
    'aidb_firebird_dictionary': 'TAIFirebirdDictionary',
    'aidb_sqlserver_dictionary': 'TAISQLServerDictionary',
    'aidb_oracle_dictionary': 'TAIOracleDictionary',
}


def normalize_art(art):
    if len(art) != 24:
        raise ValueError(f"expected 24 lines, got {len(art)}")
    out = []
    for line in art:
        if len(line) > 24:
            raise ValueError(f"line too long: {line!r}")
        out.append(line.ljust(24, '.'))
    return out


def blit(canvas, art, left, top):
    for y, line in enumerate(art):
        for x, ch in enumerate(line):
            if ch != '.' and 0 <= top + y < 24 and 0 <= left + x < 24:
                canvas[top + y][left + x] = ch


def build_canvas(icon_name):
    canvas = [list(line) for line in normalize_art(BASE_ICON)]
    badge_art, left, top = BADGES[icon_name]
    blit(canvas, badge_art, left, top)
    return [''.join(row) for row in canvas]


def make_bmp(pixels_rgb_flat):
    file_header = bytearray([
        0x42, 0x4D,
        0xF6, 0x06, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x36, 0x00, 0x00, 0x00,
    ])
    dib_header = bytearray([
        0x28, 0x00, 0x00, 0x00,
        0x18, 0x00, 0x00, 0x00,
        0x18, 0x00, 0x00, 0x00,
        0x01, 0x00,
        0x18, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0xC0, 0x06, 0x00, 0x00,
        0xC4, 0x0E, 0x00, 0x00,
        0xC4, 0x0E, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
    ])

    pixel_data = bytearray(1728)
    for y in range(24):
        src_y = 23 - y
        for x in range(24):
            src_idx = (src_y * 24 + x) * 3
            r = pixels_rgb_flat[src_idx]
            g = pixels_rgb_flat[src_idx + 1]
            b = pixels_rgb_flat[src_idx + 2]
            dest_idx = (y * 24 + x) * 3
            pixel_data[dest_idx] = b
            pixel_data[dest_idx + 1] = g
            pixel_data[dest_idx + 2] = r

    return file_header + dib_header + pixel_data


def format_lrs_resource(resource_name, bmp_bytes):
    byte_strs = "".join(f"#{b}" for b in bmp_bytes)
    return f"LazarusResources.Add('{resource_name.upper()}','BMP',[\n  {byte_strs}\n]);"


def patch_pas_file(file_path, lrs_filename):
    with open(file_path, 'r', encoding='utf-8') as f:
        original = f.read()

    content = original

    uses_match = re.search(r'\buses\b([\s\S]*?);', content, re.IGNORECASE)
    if uses_match:
        uses_clause = uses_match.group(1)
        if 'LResources' not in uses_clause:
            insert_pos = uses_match.end(1)
            separator = ', ' if uses_clause.strip() else ''
            content = content[:insert_pos] + separator + 'LResources' + content[insert_pos:]

    include_str = f"{{$I {lrs_filename}}}"
    if include_str.lower() not in content.lower():
        init_match = re.search(r'^\s*initialization\b', content, re.IGNORECASE | re.MULTILINE)
        if init_match:
            pos = init_match.end()
            content = content[:pos] + f"\n  {include_str}\n" + content[pos:]
        else:
            idx = content.rfind('end.')
            if idx == -1:
                raise RuntimeError(f"could not find end. in {file_path}")
            content = content[:idx] + f"initialization\n  {include_str}\n\n" + content[idx:]

    if content != original:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    for icon_name, unit_file in UNIT_FILES.items():
        art = build_canvas(icon_name)
        rgb = []
        for line in art:
            for char in line:
                rgb.extend(COLOR_MAP.get(char, COLOR_MAP['.']))
        bmp_bytes = make_bmp(rgb)
        lrs_filename = f'{icon_name}_icon.lrs'
        lrs_path = os.path.join(script_dir, lrs_filename)
        with open(lrs_path, 'w', encoding='utf-8') as f:
            f.write(format_lrs_resource(RESOURCE_NAMES[icon_name], bmp_bytes) + '\n')
        patch_pas_file(os.path.join(script_dir, unit_file), lrs_filename)


if __name__ == '__main__':
    main()
