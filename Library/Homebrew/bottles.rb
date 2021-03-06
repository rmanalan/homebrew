require 'tab'
require 'macos'
require 'extend/ARGV'

def bottle_filename f, bottle_revision=nil
  name = f.name.downcase
  version = f.stable.version
  bottle_revision ||= f.bottle.revision.to_i
  "#{name}-#{version}#{bottle_native_suffix(bottle_revision)}"
end

def install_bottle? f
  return true if f.downloader and defined? f.downloader.local_bottle_path \
    and f.downloader.local_bottle_path

  return false if ARGV.build_from_source?
  return false unless f.pour_bottle?
  return false unless f.build.used_options.empty?
  return false unless bottle_current?(f)
  return false if f.bottle.cellar != :any && f.bottle.cellar != HOMEBREW_CELLAR.to_s

  true
end

def built_as_bottle? f
  f = Formula.factory f unless f.kind_of? Formula
  return false unless f.installed?
  tab = Tab.for_keg(f.installed_prefix)
  # Need to still use the old "built_bottle" until all bottles are updated.
  tab.built_as_bottle or tab.built_bottle
end

def bottle_current? f
  f.bottle and f.bottle.url \
    and (not f.bottle.checksum.empty?) \
    and (f.bottle.version == f.stable.version)
end

def bottle_file_outdated? f, file
  filename = file.basename.to_s
  return nil unless f and f.bottle and f.bottle.url \
    and filename.match(bottle_regex)

  bottle_ext = filename.match(bottle_native_regex).captures.first rescue nil
  bottle_url_ext = f.bottle.url.match(bottle_native_regex).captures.first rescue nil

  bottle_ext && bottle_url_ext && bottle_ext != bottle_url_ext
end

def bottle_new_revision f
  return 0 unless bottle_current? f
  f.bottle.revision + 1
end

def bottle_native_suffix revision=nil
  ".#{MacOS.cat}#{bottle_suffix(revision)}"
end

def bottle_suffix revision=nil
  revision = revision.to_i > 0 ? ".#{revision}" : ""
  ".bottle#{revision}.tar.gz"
end

def bottle_native_regex
  /(\.#{MacOS.cat}\.bottle\.(\d+\.)?tar\.gz)$/
end

def bottle_regex
  Pathname::BOTTLE_EXTNAME_RX
end

def bottle_root_url f
  root_url = f.bottle.root_url
  root_url ||= 'https://downloads.sf.net/project/machomebrew/Bottles'
end

def bottle_url f
  "#{bottle_root_url(f)}/#{bottle_filename(f)}"
end
