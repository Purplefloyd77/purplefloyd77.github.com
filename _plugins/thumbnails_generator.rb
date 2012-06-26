require 'exifr'
require 'RMagick'
include Magick

include FileUtils

$image_extensions = [".png", ".jpg", ".jpeg", ".gif"]

module Jekyll
  class GalleryFile < StaticFile
    def write(dest)
      return false
    end
  end

  class GalleryIndex < Page
    def initialize(site, base, dir, galleries)
      @site = site
      @base = base
      @dir = dir
      @name = "index.html"

      self.process(@name)
      self.read_yaml(File.join(base, "_layouts"), "gallery_index.html")
      self.data["title"] = "Photos"
      self.data["galleries"] = []
      begin
        galleries.sort! {|a,b| b.data["date_time"] <=> a.data["date_time"]}
      rescue Exception => e
        puts e
      end
      galleries.each {|gallery| self.data["galleries"].push(gallery.data)}
    end
  end

  class GalleryPage < Page
    def initialize(site, base, dir, gallery_name)
      @site = site
      @base = base
      @dir = dir
      @name = "index.html"
      @images = []

      best_image = nil
      max_size = 300
      self.process(@name)
      self.read_yaml(File.join(base, "_layouts"), "gallery_page.html")
      self.data["gallery"] = gallery_name
      gallery_title_prefix = site.config["gallery_title_prefix"] || "Photos: "
      gallery_name = gallery_name.gsub("_", " ").gsub(/\w+/) {|word| word.capitalize}
      self.data["name"] = gallery_name
      self.data["title"] = "#{gallery_title_prefix}#{gallery_name}"
      thumbs_dir = "#{site.dest}/#{dir}/thumbs"

      FileUtils.mkdir_p(thumbs_dir, :mode => 0755)
      Dir.foreach(dir) do |image|
        if image.chars.first != "." and image.downcase().end_with?(*$image_extensions)
          @images.push(image)
          best_image = image
          @site.static_files << GalleryFile.new(site, base, "#{dir}/thumbs/", image)
          if File.file?("#{thumbs_dir}/#{image}") == false or File.mtime("#{dir}/#{image}") > File.mtime("#{thumbs_dir}/#{image}")
            begin
              m_image = ImageList.new("#{dir}/#{image}")
              m_image.resize_to_fit!(max_size, max_size)
              puts "Writing thumbnail to #{thumbs_dir}/#{image}"
              m_image.write("#{thumbs_dir}/#{image}")
            rescue
              puts "error"
              puts $!
            end
          end
        end
      end
      self.data["images"] = @images
      begin
        best_image = site.config["galleries"][self.data["gallery"]]["best_image"]
      rescue
      end
      self.data["best_image"] = best_image
      begin
        self.data["date_time"] = EXIFR::JPEG.new("#{dir}/#{best_image}").date_time.to_i
      rescue
      end
    end
  end

  class ThumbnailsGenerator < Generator
    safe true

    def generate(site)
      dir = site.config["images_dir"] || "images"
      dest = site.config["thumbnails_dir"] || "thumbnails"
      begin
        if !File.directory?(dest)
          FileUtils.mkdir_p(dest, :mode => 0755)
        end
        # generate thumbnails
        Dir.foreach(dir) do |image|
          image_path = File.join(dir, image)
          if File.file?(image_path) and image.chars.first != "." and image.downcase().end_with?(*$image_extensions)
            # generate 100x80 px
            begin
              m_image = ImageList.new(image_path)
              m_image.resize_to_fit!(100, 80)
              puts "Writing thumbnail to #{dest}/100x80-#{image}"
              m_image.write("#{dest}/100x80-#{image}")
            rescue
              puts "error"
              puts $!
            end
          end
        end

        # generate banners
        site.posts.each do |post|
          if post.data.has_key?('images') and !post.data['images'].first().nil?
            image = post.data['images'].first['image']
            image_path = File.join(dir, image)
            puts "find file #{image_path}"
            if File.file?(image_path) and image.chars.first != "." and image.downcase().end_with?(*$image_extensions)
              begin
                m_image = ImageList.new(image_path)
                m_image.resize_to_fill!(780, 140)
                puts "Writing banner to #{dest}/banner-#{image}"
                m_image.write("#{dest}/banner-#{image}")
              rescue
                puts "error"
                puts $!
              end
            end
          end
        end
      rescue Exception => e
        puts "Error : #{$!}"
        puts e.backtrace
      end
    end
  end
end