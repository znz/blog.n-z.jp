# frozen_string_literal: true

require 'jekyll-last-modified-at/determinator'

module SkipLastModifiedAt
  def last_modified_at_time
    return if page_path == 'index.html' # jekyll-paginate
    return if %r!\Atag/! =~ page_path # jekyll-tagging
    super
  end
end
class Jekyll::LastModifiedAt::Determinator
  prepend SkipLastModifiedAt
end
