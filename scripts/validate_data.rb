#!/usr/bin/env ruby
# validate_data.rb — validates product and category data files before build

require "yaml"
require "date"
require "pathname"

YAML_LOAD_OPTS = { permitted_classes: [Date, Time, Symbol] }.freeze

def safe_yaml_load(path)
  YAML.safe_load(File.read(path), **YAML_LOAD_OPTS)
rescue ArgumentError
  # Ruby < 3.1 doesn't support permitted_classes keyword; fall back
  YAML.load_file(path)
end

ROOT = Pathname.new(File.expand_path("../../", __FILE__))
DATA_DIR = ROOT / "_data"
CATEGORIES_FILE = DATA_DIR / "categories.yml"
PRODUCTS_DIR = DATA_DIR / "products"

errors = []
warnings = []

# ── 1. Load categories ────────────────────────────────────────────────────────
valid_category_ids = []

if CATEGORIES_FILE.exist?
  categories = safe_yaml_load(CATEGORIES_FILE)
  if categories.is_a?(Array)
    valid_category_ids = categories.map { |c| c["id"] }.compact
  elsif categories.is_a?(Hash)
    # Support both list format and keyed hash
    valid_category_ids = categories.keys
  end
else
  warnings << "#{CATEGORIES_FILE} not found — category validation will be skipped."
end

# ── 2. Load products ──────────────────────────────────────────────────────────
all_products = []
seen_ids = {}

unless PRODUCTS_DIR.exist?
  puts "No _data/products/ directory found. Nothing to validate."
  puts "All product data valid."
  exit 0
end

product_files = PRODUCTS_DIR.glob("*.yml").sort

if product_files.empty?
  puts "No product files found in _data/products/. Nothing to validate."
  puts "All product data valid."
  exit 0
end

product_files.each do |file|
  raw = safe_yaml_load(file)
  products = raw.is_a?(Array) ? raw : [raw]
  products.each { |p| all_products << { product: p, file: file } }
end

# ── 3. Validate each product ──────────────────────────────────────────────────
REQUIRED_FIELDS = %w[id name category short_description unit in_stock].freeze

all_products.each do |entry|
  product = entry[:product]
  file    = entry[:file]
  label   = "#{file.basename} / id=#{product['id'] || '(missing)'}"

  # Required fields
  REQUIRED_FIELDS.each do |field|
    if product[field].nil? || product[field].to_s.strip.empty?
      errors << "#{label}: missing required field '#{field}'"
    end
  end

  # Unique IDs
  id = product["id"]
  if id
    if seen_ids.key?(id)
      errors << "#{label}: duplicate id '#{id}' (also in #{seen_ids[id].basename})"
    else
      seen_ids[id] = file
    end
  end

  # Category check (only if categories were loaded)
  if valid_category_ids.any?
    cat = product["category"]
    if cat && !valid_category_ids.include?(cat)
      errors << "#{label}: unknown category '#{cat}' (valid: #{valid_category_ids.join(', ')})"
    end
  end

  # Image path check
  if product["image"] && !product["image"].to_s.strip.empty?
    image_path = ROOT / product["image"].to_s.sub(%r{^/}, "")
    unless image_path.exist?
      warnings << "#{label}: image path '#{product['image']}' does not exist yet"
    end
  end

  # price_per_unit: must be nil/null or a positive number
  price = product["price_per_unit"]
  unless price.nil?
    if !price.is_a?(Numeric) || price <= 0
      errors << "#{label}: 'price_per_unit' must be a positive number or null (got: #{price.inspect})"
    end
  end
end

# ── 4. Report ─────────────────────────────────────────────────────────────────
warnings.each { |w| puts "WARNING: #{w}" }

if errors.any?
  errors.each { |e| puts "ERROR: #{e}" }
  puts "\n#{errors.size} error(s) found in product data."
  exit 1
else
  puts "All product data valid."
  exit 0
end
