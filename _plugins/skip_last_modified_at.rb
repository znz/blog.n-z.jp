# frozen_string_literal: true

require 'jekyll-last-modified-at/determinator'

module SkipLastModifiedAt
  def last_modified_at_time
    return if 'index.html' == page_path # jekyll-paginate
    return if %r!\Atag/! =~ page_path # jekyll-tagging
    super
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
