# gmldem2tif
A converter from GML DEM by GSI to GeoTIFF

## Usage

```bash
bundle install
bundle exec ruby gmldem2tif.rb -n `nproc` input_dir output_dir
```

`-n` option specifies the number of parallel processes.

Docker

```bash
docker build -t gmldem2tif .
docker run --rm -u `id -u`:`id -g` -v /path/to/input_dir:/input -v /path/to/output_dir:/output gmldem2tif /input /output
```