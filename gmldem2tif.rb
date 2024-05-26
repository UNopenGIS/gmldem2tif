require 'nokogiri'
require 'gdal'
require 'zip'

NODATA_VALUE = -9999.0
EPSG_CODE = 6668

def convert(input, dst_path, verbose)
  puts "TIF Path: #{dst_path}" if verbose
  doc = Nokogiri::XML(input) {|config| config.huge}
  
  min_coordinates = parse_coordinate(doc.at_xpath('//gml:lowerCorner').text)
  max_coordinates = parse_coordinate(doc.at_xpath('//gml:upperCorner').text)
  raster_width, raster_height, start_coordinates = extract_dimensions(doc)
  raster_data = extract_tuple_list(doc, start_coordinates, raster_width, raster_height)

  puts "Min Coordinates: #{min_coordinates}" if verbose
  puts "Max Coordinates: #{max_coordinates}" if verbose
  puts "Raster Width: #{raster_width}, Raster Height: #{raster_height}" if verbose
  puts "Raster Data size: #{raster_data.size}, Pixels: #{raster_width * raster_height}" if verbose

  driver = Gdal::Gdal.get_driver_by_name('GTiff')
  File.delete(dst_path) if File.exist?(dst_path)
  dataset = driver.create(dst_path, raster_width, raster_height, 1, Gdal::Gdalconst::GDT_FLOAT32)

  set_geotransform(dataset, min_coordinates, max_coordinates, raster_width, raster_height)
  set_projection(dataset)

  write_raster_data(dataset, raster_data, raster_width, raster_height)

  dataset = nil
end

def parse_coordinate(coord_text)
  coord_text.split.map(&:to_f)
end

def extract_dimensions(doc)
  grid_size = doc.at_xpath('//gml:GridEnvelope/gml:high').text.split.map(&:to_i)
  raster_width = grid_size[0] + 1
  raster_height = grid_size[1] + 1
  start_coordinates = doc.at_xpath('//gml:startPoint').text.split.map(&:to_i)
  [raster_width, raster_height, start_coordinates]
end

def extract_tuple_list(doc, start_coordinates, raster_width, raster_height)
  tuple_list_text = doc.at_xpath('//gml:tupleList').text
  raster_data = Array.new(start_coordinates[1] * raster_width + start_coordinates[0], NODATA_VALUE)
  line_count = 0
  tuple_list_text.strip.each_line do |line|
    parts = line.split(',')
    raster_data << parts[1].to_f if parts.size == 2
    line_count += 1
  end
  nodata_count = raster_width * raster_height - raster_data.size
  nodata_count.times { raster_data << NODATA_VALUE }
  raster_data
end

def set_geotransform(dataset, min_coordinates, max_coordinates, raster_width, raster_height)
  min_y, min_x = min_coordinates
  max_y, max_x = max_coordinates
  pixel_width = (max_x - min_x) / raster_width
  pixel_height = (max_y - min_y) / raster_height
  geo_transform = [min_x, pixel_width, 0, max_y, 0, -pixel_height]
  dataset.set_geo_transform(geo_transform)
end

def set_projection(dataset)
  srs = Gdal::Osr::SpatialReference.new
  srs.import_from_epsg(EPSG_CODE)
  dataset.set_projection(srs.export_to_wkt)
end

def write_raster_data(dataset, raster_data, raster_width, raster_height)
  band = dataset.get_raster_band(1)
  flattened_data = raster_data.pack('f*')
  band.write_raster(0, 0, raster_width, raster_height, flattened_data)
  band.set_no_data_value(NODATA_VALUE)
  band.flush_cache
end

def process(zip_path, dst_dir, verbose)
  puts "Processing #{zip_path}" if verbose
  Zip::File.open(zip_path) do |zip_file|
    zip_file.each do |entry|
      next unless entry.name.downcase.end_with?('.xml')
      dst_name = entry.name.sub('.xml', '.tif')
      dst_path = "#{dst_dir}/#{dst_name}"
      input = entry.get_input_stream.read
      convert(input, dst_path, verbose)
    end
  end
end

def main(zip_dir, dst_dir, verbose)
  Dir.glob("#{zip_dir}/*.zip") do |zip_path|
    process(zip_path, dst_dir, verbose)
  end
end

def help
  puts "Usage: ruby gmldem2tif.rb [--verbose] <zip_dir> <dst_dir>"
end

def parse_args
  args = ARGV
  verbose = args.delete("--verbose")
  help if args.length < 2 || args.length > 3
  zip_dir = args[-2]
  dst_dir = args[-1]
  [zip_dir, dst_dir, verbose]
end

def run
  zip_dir, dst_dir, verbose = parse_args
  Dir.mkdir(dst_dir) unless Dir.exist?(dst_dir)
  main(zip_dir, dst_dir, verbose)
end

run
