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
- `-c, --compression TYPE` - Compression type: lzw, deflate, none (default: lzw)

### Compression Types

- **lzw** (default) - LZW compression with predictor. Recommended for DEMs. Provides excellent compression (60-80% space savings) with wide GIS software compatibility.
- **deflate** - DEFLATE compression with predictor. Alternative to LZW with similar compression ratios.
- **none** - No compression. Creates uncompressed TIFF files.

All compressed outputs use tiling (256x256 blocks) and predictor=2 (horizontal differencing) for optimal compression of DEM data.

### Examples

```bash
# Basic usage with default LZW compression
bundle exec ruby gmldem2tif.rb -n `nproc` input_dir output_dir

# Use DEFLATE compression instead
bundle exec ruby gmldem2tif.rb -n `nproc` -c deflate input_dir output_dir

# Create uncompressed files
bundle exec ruby gmldem2tif.rb -n `nproc` -c none input_dir output_dir

# Verbose mode to see compression details
bundle exec ruby gmldem2tif.rb -v -n `nproc` input_dir output_dir
```

## Docker

```bash
docker build -t gmldem2tif .
docker run --rm -u `id -u`:`id -g` -v /path/to/input_dir:/input -v /path/to/output_dir:/output gmldem2tif /input /output
```

The Docker image uses LZW compression by default. To use different compression options, override the entrypoint:

```bash
docker run --rm -u `id -u`:`id -g` -v /path/to/input_dir:/input -v /path/to/output_dir:/output \
  --entrypoint /bin/bash gmldem2tif \
  -c "bundle exec ruby gmldem2tif.rb -n $(nproc) -c deflate /input /output"
```

## Features

- **Lossless Compression**: LZW and DEFLATE compression preserve all elevation data exactly
- **Optimized for DEMs**: Horizontal differencing predictor improves compression for spatially correlated elevation data
- **Cloud-Optimized**: Tiled output with 256x256 block size for efficient partial reads
- **High Performance**: Multi-process parallel processing support
- **Interoperable**: Compatible with all major GIS software (QGIS, ArcGIS, GDAL, etc.)