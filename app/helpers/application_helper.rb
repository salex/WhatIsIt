module ApplicationHelper
  def title(page_title)
    content_for(:title) { page_title }
  end
  
  def hash_to_info(hash)
    return unless hash.class == Hash
    info = ""
    hash.each do |k,v|
      info += "#{k}::#{v}\n"
    end
    return info
  end
end
