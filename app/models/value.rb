class Value < ActiveRecord::Base
  has_many :tags
  has_many :subjects, :through => :tags
  store :info, :assessors => :info
  
  attr_accessible :info, :name
  validates_presence_of :name
  before_save :set_info
  
  def set_info
    unless self.info.class == Hash
      self.info =  Value.info_to_hash(self.info)
    end
  end
  
  def self.info_to_hash(info)
    hash = {}
    return hash if info.blank?
    info.gsub!("\r","::")
    info.gsub!("\n","")
    elements = info.split("::")
    elem_count = elements.count
    if elem_count == 1
      hash = {"info" => info}
    elsif elem_count.odd?
      1.upto(elem_count) do |i|
        hash["info"+i.to_s] = (elements[i-1]).strip
      end
    else
      0.step(elem_count - 1,2) do |i|
        hash[elements[i].strip] = (elements[i+1]).strip
      end
    end
    hash
  end
  
  def subject
    self.tags.first.subject
  end
  
  
end
