module HeritageHarvestRanch
  class ProductPageGenerator < Jekyll::Generator
    safe true
    priority :normal

    def generate(site)
      products_data = site.data["products"] || {}
      categories    = site.data["categories"] || []

      all_products = []
      products_data.each_value do |file_products|
        list = file_products.is_a?(Array) ? file_products : [file_products]
        all_products.concat(list)
      end

      all_products.sort_by! { |p| p["display_order"].to_i }

      all_products.each do |product|
        site.pages << ProductPage.new(site, product)
      end

      categories.each do |category|
        cat_products = all_products.select { |p| p["category"] == category["id"] }
        site.pages << CategoryPage.new(site, category, cat_products)
      end

      site.data["all_products"] = all_products
    end
  end

  class ProductPage < Jekyll::Page
    def initialize(site, product)
      @site = site
      @base = site.source
      @dir  = "products/#{product['id']}"
      @name = "index.html"

      self.process(@name)
      self.data = {
        "layout"      => "product",
        "title"       => product["name"],
        "description" => product["short_description"],
        "product"     => product,
      }
      self.data["image"] = product["image"] if product["image"]
      self.content = ""
    end
  end

  class CategoryPage < Jekyll::Page
    def initialize(site, category, products)
      @site = site
      @base = site.source
      @dir  = "products/category/#{category['id']}"
      @name = "index.html"

      self.process(@name)
      self.data = {
        "layout"            => "category",
        "title"             => category["name"],
        "description"       => category["description"],
        "category"          => category,
        "category_products" => products,
      }
      self.data["image"] = category["hero_image"] if category["hero_image"]
      self.content = ""
    end
  end
end
