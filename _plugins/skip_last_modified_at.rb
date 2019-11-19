# frozen_string_literal: true

require 'jekyll-last-modified-at/determinator'

module SkipLastModifiedAt
  def last_modified_at_time
    return if 'index.html' == page_path # jekyll-paginate
    return if %r!\Atag/! =~ page_path # jekyll-tagging
    super
  end
end
class Jekyll::LastModifiedAt::Determinator
  prepend SkipLastModifiedAt
end
