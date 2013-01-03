class Tag < ActiveRecord::Base
  belongs_to :subject
  belongs_to :value, :dependent => :destroy
  validates_presence_of :name
  
  attr_accessible :name, :subject_id, :value_id

  def append_value(value,info="")
    new_tag = self.dup
    value = Value.create!(name: value, info: info)
    new_tag.value = value
    if new_tag.save
      return true, { :message => "Stuffing..., Indexing - Got it"}
    else
      return false, { :message => "I'm sorry, Dave. I'm afraid I can't do that. I Be Broke"}
    end
  end
  
  def tag_name_values
    value = Value.where(:id => tag_name_ids)
  end
  
  def tag_name_ids
    tag_ids = Tag.where('tags.name ilike ?',self.name).where(:subject_id => self.subject_id).pluck(:value_id)
  end
  alias_method :siblings, :tag_name_ids
  alias_method :sibling_values, :tag_name_values
  
  def values
    v = Value.where(:id => self.siblings).as_json(:except => [:created_at, :updated_at ])
  end
  
end
