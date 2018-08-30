# frozen_string_literal: true

require 'jekyll-last-modified-at/determinator'

module SkipLastModifiedAt
  TIME_CACHE = {}

  def init_time_cache
    TIME_CACHE['index.html'] = nil # jekyll-paginate
    if is_git_repo?(site_source)
      ::Jekyll::LastModifiedAt::Executor.sh(
        'git',
        '--git-dir',
        top_level_git_directory,
        'log',
        *%w"-m -r --name-only --no-color --pretty=format:%ct -z",
      ).each_line("\0\0", chomp: true) do |commit|
        commit.sub!(/\A\d+\n/, '')
        last_commit_date = $&.to_i
        commit.split("\0").each do |file|
          TIME_CACHE["#{site_source}/#{file}"] ||= last_commit_date
        end
      end
    end
  end

  def last_modified_at_time
    return TIME_CACHE[page_path] if TIME_CACHE.key?(page_path)
    if %r!\Atag/! =~ page_path # jekyll-tagging
      TIME_CACHE[page_path] = nil
      return
    end
    init_time_cache if TIME_CACHE.empty?
    TIME_CACHE[page_path] = super
  end

  def last_modified_at_unix
    if is_git_repo?(site_source)
      last_commit_date = ::Jekyll::LastModifiedAt::Executor.sh(
        'git',
        '--git-dir',
        top_level_git_directory,
        'log',
        '--format="%ct"',
        '-1', ## add
        '--',
        relative_path_from_git_dir
      )[/\d+/]
      # last_commit_date can be nil iff the file was not committed.
      (last_commit_date.nil? || last_commit_date.empty?) ? mtime(absolute_path_to_article) : last_commit_date
    else
      mtime(absolute_path_to_article)
    end
  end
end
class Jekyll::LastModifiedAt::Determinator
  prepend SkipLastModifiedAt
end
