require 'fileutils'
require 'pathname'
require 'rake'

module Rake
  module Portile
    INIT = Rake::Task.define_task(:init)
    FETCH = Rake::Task.define_task(:fetch)
    BUILD = Rake::Task.define_task(:build)
    CLEAN = Rake::Task.define_task(:clean)

    FETCH.add_description('Fetch everything')
    BUILD.add_description('Build everything')
    CLEAN.add_description('Clean everything')

    Rake::Task.define_task(:'symlink:bin' => :build) do
      bin_dir = Rake::Portile.target.join('bin').tap(&:mkpath)
      Rake::Portile.ports.each do |_, port|
        FileUtils.ln_sf(Pathname(port[:recipe].path).join('bin').children, bin_dir)
      end
    end

    Rake::Task.define_task(:'symlink:sbin' => :build) do
      sbin_dir = Rake::Portile.target.join('sbin').tap(&:mkpath)
      Rake::Portile.ports.each do |_, port|
        FileUtils.ln_sf(Pathname(port[:recipe].path).join('sbin').children, sbin_dir)
      end
    end

    class << self
      def ports
        @ports ||= {}
      end

      def target
        @target ||= Pathname('/opt')
      end

      def target=(val)
        @target = Pathname(val).realpath
      end

      def jobs
        @jobs ||= 1
      end

      def jobs=(val)
        @jobs = Integer(val)
      end
    end

    module_function def def_port(name, version, depends: [], &block)
      name = name.to_s
      id = name.to_sym
      depends = depends.map(&:to_sym)

      port = Rake::Portile.ports[id] = {
        depends: depends,
      }

      init = Rake::Task.define_task(:"init:#{id}" => depends.map {|depid| :"init:#{depid}"}) do
        recipe = port[:recipe] = MiniPortile.new(name, version)
        recipe.target = Rake::Portile.target
        def recipe.compile
          execute('compile', %Q(#{make_cmd} --jobs=#{Rake::Portile.jobs}),)
        end
        def recipe.install
          execute('install', %Q(#{make_cmd} install-strip),) unless installed?
        end
        block.yield(recipe, depends.map {|id| Rake::Portile.ports.fetch(id)[:recipe] })
      end

      fetch = Rake::Task.define_task(:"fetch:#{id}" => [:init]) do
        recipe = port.fetch(:recipe)
        recipe.download unless recipe.downloaded?
      end
      fetch.add_description("Fetch #{name}")

      build = Rake::Task.define_task(:"build:#{id}" => [:init, *depends.map {|depid| :"build:#{depid}"}]) do
        recipe = port.fetch(:recipe)
        recipe.cook
        recipe.activate
      end
      build.add_description("Build #{name}")

      clean = Rake::Task.define_task(:"clean:#{id}" => [:init]) do
        recipe = port.fetch(:recipe)
        FileUtils.rm_rf(recipe.send(:tmp_path))
      end
      clean.add_description("Clean #{name}")

      INIT.enhance([init])
      FETCH.enhance([fetch])
      BUILD.enhance([build])
      CLEAN.enhance([clean])
    end
  end
end
