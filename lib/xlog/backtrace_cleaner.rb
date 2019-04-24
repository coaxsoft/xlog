# this BacktraceCleaner is "stolen" from Rails in order to avoid dependencies
# https://github.com/rails/rails/blob/master/activesupport/lib/active_support/backtrace_cleaner.rb

module Xlog
  class BacktraceCleaner
    def initialize
      @filters, @silencers = [], []
      add_gem_filter
      add_gem_silencer
      add_stdlib_silencer
    end

    # Returns the backtrace after all filters and silencers have been run
    # against it. Filters run first, then silencers.
    def clean(backtrace, kind = :silent)
      filtered = filter_backtrace(backtrace)

      case kind
      when :silent
        silence(filtered)
      when :noise
        noise(filtered)
      else
        filtered
      end
    end
    alias :filter :clean

    # Adds a filter from the block provided. Each line in the backtrace will be
    # mapped against this filter.
    #
    #   # Will turn "/my/rails/root/app/models/person.rb" into "/app/models/person.rb"
    #   backtrace_cleaner.add_filter { |line| line.gsub(Rails.root, '') }
    def add_filter(&block)
      @filters << block
    end

    # Adds a silencer from the block provided. If the silencer returns +true+
    # for a given line, it will be excluded from the clean backtrace.
    #
    #   # Will reject all lines that include the word "puma", like "/gems/puma/server.rb" or "/app/my_puma_server/rb"
    #   backtrace_cleaner.add_silencer { |line| line =~ /puma/ }
    def add_silencer(&block)
      @silencers << block
    end

    # Removes all silencers, but leaves in the filters. Useful if your
    # context of debugging suddenly expands as you suspect a bug in one of
    # the libraries you use.
    def remove_silencers!
      @silencers = []
    end

    # Removes all filters, but leaves in the silencers. Useful if you suddenly
    # need to see entire filepaths in the backtrace that you had already
    # filtered out.
    def remove_filters!
      @filters = []
    end

    private

    FORMATTED_GEMS_PATTERN = /\A[^\/]+ \([\w.]+\) /

    def add_gem_filter
      gems_paths = (Gem.path | [Gem.default_dir]).map { |p| Regexp.escape(p) }
      return if gems_paths.empty?

      gems_regexp = %r{(#{gems_paths.join('|')})/(bundler/)?gems/([^/]+)-([\w.]+)/(.*)}
      gems_result = '\3 (\4) \5'
      add_filter { |line| line.sub(gems_regexp, gems_result) }
    end

    def add_gem_silencer
      add_silencer { |line| FORMATTED_GEMS_PATTERN.match?(line) }
    end

    def add_stdlib_silencer
      add_silencer { |line| line.start_with?(RbConfig::CONFIG["rubylibdir"]) }
    end

    def filter_backtrace(backtrace)
      @filters.each do |f|
        backtrace = backtrace.map { |line| f.call(line) }
      end

      backtrace
    end

    def silence(backtrace)
      @silencers.each do |s|
        backtrace = backtrace.reject { |line| s.call(line) }
      end

      backtrace
    end

    def noise(backtrace)
      backtrace.select do |line|
        @silencers.any? do |s|
          s.call(line)
        end
      end
    end
  end
end