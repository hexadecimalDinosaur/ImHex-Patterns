#pragma author WerWolv
#pragma description Windows Icon (.ico) or Cursor (.cur)

#pragma endian little

import std.sys;
import * from png as PNG;
import bmp as BMP;

#pragma MIME image/vnd.microsoft.icon
#pragma MIME image/x-icon
#pragma MIME image/icon
#pragma MIME image/ico
#pragma MIME text/ico
#pragma MIME application/ico

enum ImageType : u16 {
    Icon = 1,
    Cursor = 2
};

struct ICONDIR {
    u16 reserved [[hidden]];
    ImageType type;
    u16 num_images;
};

struct ImageData {
    u8 data[parent.image_data_size] [[hidden, no_unique_address]];
    be u64 png_magic [[hidden, no_unique_address]];
    if (png_magic == 0x89504e470d0a1a0a) {
        PNG png_data @ $ [[inline]];
    } else {
        u32 bmInfoHeaderSize [[hidden, no_unique_address]];
        match (bmInfoHeaderSize) {
            (40): BMP::BitmapInfoHeaderV1 bmih;
            (52): BMP::BitmapInfoHeaderV2 bmih;
            (56): BMP::BitmapInfoHeaderV3 bmih;
            (108): BMP::BitmapInfoHeaderV4 bmih;
            (124): BMP::BitmapInfoHeaderV5 bmih;
            (_): BMP::BitmapInfoHeaderV1 bmih;
        }
        if (bmih.biSize > sizeof(bmih))
            padding[bmih.biSize - sizeof(bmih)];
        if (bmih.biBitCount <= 8)
        {
            if (bmih.biClrUsed > 0 )
                BMP::Colors rgbq[bmih.biClrUsed];
            else
                BMP::Colors rgbq[1 << bmih.biBitCount];
            u8 lineData[parent.image_data_size - sizeof(bmih) - sizeof(rgbq)];
        } else {
            u8 lineData[parent.image_data_size - sizeof(bmih)];
        }
    }
};

struct ICONDIRENTRY {
    u8 width, height;
    u8 num_colors;
    u8 reserved [[hidden]];

    if (header.type == ImageType::Icon) {
        u16 color_planes;
        u16 bits_per_pixel;
    } else if (header.type == ImageType::Cursor) {
        u16 horizontal_hotspot_coordinate;
        u16 vertical_hotspot_coordinate;
    }

    u32 image_data_size;
    ImageData *image_data : u32 [[fixed_size(image_data_size)]];
};

ICONDIR header @ 0x00;
ICONDIRENTRY images[header.num_images] @ $;

std::assert(header.reserved == 0x00, "Invalid ICO header");
