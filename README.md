# gmldem2tif
A converter from GML DEM by GSI to GeoTIFF with compression support

## Usage

```bash
bundle install
bundle exec ruby gmldem2tif.rb [options] input_dir output_dir
```

### Options

- `-n, --nproc NUM` - Number of parallel processes (default: 1)
- `-v, --verbose` - Enable verbose output
- `-c, --compression TYPE` - Compression type: zstd, zstd-max, lzw, deflate, none (default: zstd)

### Compression Types

- **zstd** (default) - ZSTD compression at level 6 with floating-point predictor. Modern, efficient compression with excellent ratio and fast decompression. Requires GDAL >= 3.1. Recommended for most use cases.
- **zstd-max** - ZSTD compression at level 9 with floating-point predictor. Maximum compression for archival purposes where encoding time is acceptable.
- **lzw** - LZW compression with floating-point predictor. Legacy compatibility option for older GIS software.
- **deflate** - DEFLATE compression with floating-point predictor. Legacy compatibility option, alternative to LZW.
- **none** - No compression. Creates uncompressed TIFF files.

All compressed outputs use:
- **PREDICTOR=3**: Floating-point predictor optimized for DEM data (FLOAT32)
- **Tiling**: 512x512 blocks for cloud-optimized GeoTIFFs with efficient partial reads
- **Internal tiling**: Improves random access and cloud workflows

### Why ZSTD?

ZSTD (Zstandard) provides better compression ratios than LZW/DEFLATE while maintaining fast decompression speeds. Level 6 offers an excellent balance between compression time and file size for production workflows. Use `zstd-max` (level 9) when creating archives where encoding time is less critical.

### Examples

```bash
# Basic usage with default ZSTD compression (level 6)
bundle exec ruby gmldem2tif.rb -n $(nproc) input_dir output_dir

# Use maximum ZSTD compression for archival
bundle exec ruby gmldem2tif.rb -n $(nproc) -c zstd-max input_dir output_dir

# Use LZW for legacy compatibility
bundle exec ruby gmldem2tif.rb -n $(nproc) -c lzw input_dir output_dir

# Use DEFLATE compression
bundle exec ruby gmldem2tif.rb -n $(nproc) -c deflate input_dir output_dir

# Create uncompressed files
bundle exec ruby gmldem2tif.rb -n $(nproc) -c none input_dir output_dir

# Verbose mode to see compression details
bundle exec ruby gmldem2tif.rb -v -n $(nproc) input_dir output_dir
```

## Docker

```bash
docker build -t gmldem2tif .
docker run --rm -u $(id -u):$(id -g) -v /path/to/input_dir:/input -v /path/to/output_dir:/output gmldem2tif /input /output
```

The Docker image uses ZSTD compression by default. To use different compression options, override the entrypoint:

```bash
docker run --rm -u $(id -u):$(id -g) -v /path/to/input_dir:/input -v /path/to/output_dir:/output \
  --entrypoint /bin/bash gmldem2tif \
  -c "bundle exec ruby gmldem2tif.rb -n $(nproc) -c zstd-max /input /output"
```

## Features

- **Modern Compression**: ZSTD provides better compression ratios than legacy formats while maintaining fast decompression
- **Lossless**: All compression options preserve elevation data exactly
- **Optimized for Floating-Point DEMs**: Uses PREDICTOR=3 (floating-point predictor) for FLOAT32 elevation data
- **Cloud-Optimized**: Tiled output with 512x512 block size for efficient partial reads and cloud workflows
- **High Performance**: Multi-process parallel processing support
- **Flexible**: Multiple compression options from maximum compression (zstd-max) to legacy compatibility (lzw/deflate)
- **Interoperable**: Compatible with GDAL >= 3.1 and all major modern GIS software (QGIS, ArcGIS, etc.)

## Requirements

- **GDAL >= 3.1** for ZSTD compression support
- For legacy compatibility (older GDAL versions), use `-c lzw` or `-c deflate`