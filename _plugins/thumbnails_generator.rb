require 'exifr'
require 'RMagick'
include Magick

include FileUtils

$image_extensions = [".png", ".jpg", ".jpeg", ".gif"]

module Jekyll
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
            # generate 200x80 px
            dest_path = File.join(dest, "200x80-#{image}")
            if !File.file?(dest_path)
              begin
                m_image = ImageList.new(image_path)
                m_image.resize_to_fit!(200, 80)
                puts "Writing thumbnail to #{dest}/200x80-#{image}"
                m_image.write(dest_path)
              rescue
                puts "error"
                puts $!
              end
            end
          end
        end

        # generate banners
        site.posts.each do |post|
          if post.data.has_key?('images') and !post.data['images'].first().nil?
            image = post.data['images'].first['file']
            image_path = File.join(dir, image)
            dest_path = File.join(dest, "banner-#{image}")
            if File.file?(image_path) and image.chars.first != "." and image.downcase().end_with?(*$image_extensions) and !File.file?(dest_path)
              begin
                m_image = ImageList.new(image_path)
                m_image.resize_to_fill!(780, 140)
                puts "Writing banner to #{dest_path}"
                m_image.write(dest_path)
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
