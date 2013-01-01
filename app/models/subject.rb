class Subject < ActiveRecord::Base
  has_many :tags, :dependent => :destroy
  has_many :values, :through => :tags
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
  
  attr_accessible :name
  
  #ActiveRecord::Base.connection.reset_pk_sequence!('subjects')
  def find_value(tag,value)
    self.values.includes(:tags).where('tags.name ilike ?',tag).where('values.name ilike ?',value).first
  end
  
  def find_values(value)
    self.values.where('values.name ilike ?',value)
  end

  def self.new_tuple(subject,tag,value,info="")
    begin
      self.transaction do
        subject = self.create!(name: subject)
        value = Value.create!(name: value, info: info)
        tag = Tag.new(name: tag)
        tag.subject = subject
        tag.value = value
        tag.save
      end
    rescue ActiveRecord::RecordInvalid
      return false, {:message => "Whoa's is me. You tried to add a duplicate subject #{subject}"}
    else
      return true, { :message => "Stuffing..., Indexing - Got it"}
    end
      
  end
  
  def self.new_tag_and_value(subject,tag,value,info="")
    subject = self.where('subjects.name ilike ?', subject).first
    unless subject.nil?
      begin
        self.transaction do
          tag = Tag.new(name: tag)
          value = Value.create!(name: value, info: info)
          tag.subject = subject
          tag.value = value
          tag.save
        end
      rescue ActiveRecord::RecordInvalid
        return false, { :message => "Whoa's is me. Looks like I have a problem in save a new tag and value"}
      else
        return true, { :message => "Stuffing..., Indexing - Got it"}
      end
    else
      return false, { :message => "Whoa's is me. I could not find the subject"}
    end
  end
  
  def new_tag_and_value(tag,value,info="")
    begin
      self.transaction do
        tag = Tag.new(name: tag)
        value = Value.create!(name: value, info: info)
        tag.subject = self
        tag.value = value
        tag.save
      end
    rescue ActiveRecord::RecordInvalid
      return false, { :message => "Whoa's is me. Looks like I have a problem in save a new tag and value"}
    else
      return true, { :message => "Stuffing..., Indexing - Got it"}
    end
  end
  
  # NOTE: make this an instance call
  def self.change_value(subject,tag,value,new_value,new_info="")
    subject = self.where('subjects.name ilike ?', subject).first
    unless subject.nil?
      value = subject.find_value(tag,value)
      unless value.nil?
        value.name = new_value
        value.info = new_info unless new_info.blank?
        value.save
      else
        return {:result => "error", :message => "Whoa's is me. The Value #{value} does not exists for #{tag}"}
      end
    else
      return {:result => "error", :message => "Whoa's is me. I can't find the subject #{subject}"}
    end
  end
  
  
end
