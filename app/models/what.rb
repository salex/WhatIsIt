class What
  attr_accessor :subject, :tag, :value, :info, :response, :target, :str
  def initialize(attributes = {})
    @tuple = reset_tuple
     
    if attributes
      attributes.each do |name, value|
        send("#{name}=", value)
      end
    end
  end
  

  def query(str)
    self.str = str
    command, qstr = get_command_and_query(str) # sets command if there and remove it from input str
    return {'error' => "Whoa! You didn't ask a question."} if qstr.blank?
    info = get_info(qstr) # gets info from qstr
    subject,tag,value,target = get_subject_tag_value(qstr) # get the possible attributes from qstr
  # the things we can do in query
    query = true 
    append_value = append_tag = false
    relate =  tag.include?(':')
    forget = command == 'forget'
    change = command == 'change'
    assign = (command == 'new') && !value.blank?
    get_tuple(subject,tag,value,target)
    
    if target == 'value' 
      append_value = @tuple[:subject][:has] && @tuple[:tag][:has] && !@tuple[:value][:has]
      append_tag = @tuple[:subject][:has] && !@tuple[:tag][:has] && !value.blank?
      append_value =  append_value && @tuple[:value][:ilike].nil?
      assign = !@tuple[:subject][:has] && !tag.blank? && !value.blank? && @tuple[:subject][:ilike].nil?
    end
    
    puts "QQQQQuuuuuEEEEEERRRRRRyyyy cmd #{command} q #{query} t #{tag} t #{target} r #{relate} av #{append_value} at #{append_tag} as #{assign}"
  # figure out what to query and what to return
    if forget
      results = get_action_results("forget")
    elsif relate
      results = relate_action
    elsif change
      results = get_action_results("edit")
    elsif append_value
      results = {action: 'edit', what: "append_value", tag_id: @tuple[:tag][:id]}.merge(get_instance_attr)
    elsif append_tag
      results = {action: 'edit', what: "new_tag_and_value", :subject_id => @tuple[:subject][:id]}.merge(get_instance_attr)
    elsif assign
      results = assign_action
    elsif query  && (command == 'who') && (target == 'subject') 
      results = {action: "display_who", hash: who_s(subject)}.merge(get_instance_attr)# who is a subject dump
      
    elsif query && (target == 'value') 
      results =  {action: "display_value",  hash: who_s_value(subject,tag,value)}.merge(get_instance_attr) # query all attributes for a subject.tag
   
    elsif query && (target == 'tag') 
      results =  {action: "display_tag",  hash: who_s_tag(subject,tag)}.merge(get_instance_attr) # query all attributes for a subject.tag
      
      
    elsif query && (target == 'subject') #!subject.blank? 
      
      results = {action: "display_objects",  hash: object_s(subject)}.merge(get_instance_attr) # query all attributes by type
      
    else
      results = { :debug => {message: "What::Unknown query action", command: command}.merge(get_instance_attr)}
    end
    results
  end
  
  # ACTION METHODS
  def relate_action
    tags = @tag.split(':')
    return {error: {message: "Invalid relation: #{@tag}"}} if tags.size != 2
    tuple0 = get_tuple(@subject,tags[0],@value,'value')
    tuple1 = get_tuple(@value,tags[1],@subject,'value')
    tuple0_exists = tuple0[:subject][:has] && tuple0[:tag][:has] && tuple0[:value][:has]
    tuple1_exists = tuple1[:subject][:has] && tuple1[:tag][:has] && tuple1[:value][:has]
    return {error: {message: "Relation already exists: #{@str}"}} if tuple1_exists && tuple0_exists
    relations = [{subject: @subject, tag: tags[0], value: @value, tuple: tuple0}, {subject: @value, tag: tags[1], value: @subject,tuple: tuple1}]
    #response = { :debug => {message: "test relate", command: 'relate', relations: relations }.merge(get_instance_attr)}
    response = { :action => 'relate', :what => "",  relations: relations}.merge(get_instance_attr)
    puts "RESPONSE  #{response.inspect}"
    return response
  end
  
  def assign_action
    if @tuple[:subject][:has] # used new's with existing subject
      results = {:error => {:message => "Whoa's is me. You tried to add a duplicate subject #{subject}"}}
    else
      results = {action: 'edit', what: "new_tuple"}.merge(get_instance_attr)
    end
  end
  
  def get_action_results(action)  
    subject_o = tag_o = value_o = nil
    subject_o = Subject.find(@tuple[:subject][:id])
    
    if @target == 'subject' && !subject_o.nil?
      tags = subject_o.tags.select(:name).uniq.pluck('tags.name')
      values = subject_o.values.select('values.name').uniq.pluck('values.name')
      return  get_instance_attr.merge({action: action, what: @target, subject_id: subject_o.id, id: subject_o.id, tags: tags, values: values})
    end
    tag_o = Tag.where(id: @tuple[:tag][:id])
    
    if @target == 'tag' && !tag_o.empty?
      tags = tag_o.select(:name).uniq.pluck('tags.name')
      values = Value.where(:id => @tuple[:tag][:id]).pluck('values.name')
      return  get_instance_attr.merge({action: action, what: @target, tag_id: @tuple[:tag][:id], tags: tags, values: values})
    end
    value_o = Value.where(id: @tuple[:value][:id])
    vids = value_o.pluck('values.id')
    
    if target == 'value' && !value_o.empty?
      return get_instance_attr.merge({action: action, what: @target,  value_id: vids ,values: value_o.pluck('values.name')})
    else
      return get_instance_attr.merge({action: 'error', what: "tuple not found"})
    end
  end
  
  def get_instance_attr
    return { subject: @subject, tag: @tag, value: @value, :info => @info, target: @target, str: @str}
  end

# HELPER METHODS  
  def array_to_ilike(col_name,keys)
    ilike = [keys.map {|i| "#{col_name} ILiKE ? "}.join(" OR "), *keys ]
    #ilike = [keys.size.times.map{"#{col_name} ILIKE ?"}.join(' OR '), *keys ]
   end  
  
  
  def get_tuple(subject,tag,value,target)
    @tuple = reset_tuple
    if subject.include?("|")
      keys = subject.split("|")
      @tuple[:subject][:ilike] = array_to_ilike('subjects.name',keys)
    end
    if tag.include?("|")
      keys = tag.split("|")
      @tuple[:tag][:ilike] = array_to_ilike('tags.name',keys)
    end
    if value.include?("|")
      keys = value.split("|")
      @tuple[:value][:ilike] = array_to_ilike('values.name',keys)
    end
    subject_o = Subject.where("name ilike ?", subject).first
    return @tuple if subject_o.nil?
    
        
    @tuple[:subject][:has] = true
    @tuple[:subject][:id] = subject_o.id
    @tuple[:subject][:name] = subject_o.name
    return @tuple if target == 'subject'
        
    tag_o = subject_o.tags.where("tags.name ilike ?", tag)
    return @tuple if tag_o.empty?
    
    @tuple[:tag][:has] = true
    @tuple[:tag][:id] = tag_o.pluck('tags.id')
    @tuple[:tag][:name] = tag
    return @tuple if target == 'tag'
    
    value_o = subject_o.values.where("values.name ilike ?", value).where(:id => @tuple[:tag][:id])    
    return @tuple if value_o.empty?
    
    @tuple[:value][:has] = true
    @tuple[:value][:id] = value_o.pluck('values.id')   
    @tuple[:value][:name] = value 
    return @tuple
  end
    
  def object_s(name)
    # What's object
    if name.include?("|")
      v_ilike = array_to_ilike('values.name',name.split("|"))
      s_ilike = array_to_ilike('subjects.name',name.split("|"))
      t_ilike = array_to_ilike('tags.name',name.split("|"))
    else
      v_ilike = ['values.name ilike ?',name]
      s_ilike = ['subjects.name ilike ?',name]
      t_ilike = ['tags.name ilike ?',name]
    end
    
    wa = Subject.where(s_ilike) # TODO Can't have multiple subjects?, get rid of
    ba = Tag.where(t_ilike)
    ia = Value.where(v_ilike)
    wh = subjects_hash(wa) # TODO Can't have multiple subjects?, get rid of
    bh = tags_hash(ba)
    ih = values_hash(ia)
    result = wh.merge(bh.merge(ih))
  end
  
  def who_s(name)
    # Who's Subject's
    who = Subject.includes([:tags, :values]).where("name ilike ?", name)
    hash = subject_hash(who)
  end

  def who_s_tag(name, tag)
    # What's Subject's Tag's
    s_ilike = @tuple[:subject][:ilike] ||= ['subjects.name ilike ?',name]
    relations = []
    if @tuple[:tag][:ilike]
      tags = Tag.joins(:subject).where(s_ilike).where(@tuple[:tag][:ilike]) #"subjects.name ilike ?", name
    else
      tags = Tag.joins(:subject).where(s_ilike).where('tags.name ilike ?',tag)
    end
    tags.each do |tag|
      relations << tag_hash(tag,false)
    end
    unless relations.empty?
      result = {:tags => relations}
    else
      result = {:relations => tuple_relations(name,tag)}
    end
    return result
  end

  def who_s_value(subject,tag,value)
    # What's Subject's Tag's Value
    v_ilike = @tuple[:value][:ilike] ||= ['values.name ilike ?',value]
    t_ilike = @tuple[:tag][:ilike] ||= ['tags.name ilike ?',tag]
    s_ilike = @tuple[:subject][:ilike] ||= ['subjects.name ilike ?',subject]
    v = Value.where(v_ilike).joins(:subjects) 
    v = v.joins(:subjects).where(s_ilike)
    v = v.joins(:tags).where(t_ilike)
    if v.count < 2
      hash = value_hash(v)
    else
      hash = values_hash(v)
    end
  end
    
  def tuple_relations(name1,name2)
    # Always wanted to use the name tuple, but it is more of a set (unordered)
    # Find a set of records in model1 that are related to a set of records in model2
    # This only finds relations not defined in ActiveRecord. It is really just a filter added to what is defined.
    # Tag belongs to Subject and Value, so it knows *specific* stuff. But Tag names are not unique
    # and can belong to the same Subject, but different Values.
    # Think ancestry: JanL.Son.SteveR, JanL.Son.JamesV SteveV.Son.SteveR, SteveV.Son.JamesV
    # JanL.Son return both SteveR and JamesV Values and defined by model relations
    # JanL.JamesV returns the joining Tag with the name Son (one)
    # Son.JamesV returns the related Subjects (SteveV and JanL)
    if name1.include?("|")
      v_ilike1 = array_to_ilike('values.name',name1.split("|"))
      s_ilike1 = array_to_ilike('subjects.name',name1.split("|"))
      t_ilike1 = array_to_ilike('tags.name',name1.split("|"))
    else
      v_ilike1 = ['values.name ilike ?',name1]
      s_ilike1 = ['subjects.name ilike ?',name1]
      t_ilike1 = ['tags.name ilike ?',name1]
    end
      
    if name2.include?("|")
      v_ilike2 = array_to_ilike('values.name',name2.split("|"))
      s_ilike2 = array_to_ilike('subjects.name',name2.split("|"))
      t_ilike2 = array_to_ilike('tags.name',name2.split("|"))
    else
      v_ilike2 = ['values.name ilike ?',name2]
      s_ilike2 = ['subjects.name ilike ?',name2]
      t_ilike2 = ['tags.name ilike ?',name2]
    end
    
    
    sets = [] # an array of relations
    # Tries both Value.Subject and Subject.Value ex JanL.JamesV and/or JamesV.JanL
      sets += Value.where(v_ilike1).joins(:subjects).where(s_ilike2)
      sets += Value.where(v_ilike2).joins(:subjects).where(s_ilike1)
    # Tries both Value.Subject and Subject.Value ex JanL.JamesV and/or JamesV.JanL
      sets += Tag.where(t_ilike1).joins(:value).where(v_ilike2)
      sets += Tag.where(t_ilike2).joins(:value).where(v_ilike1)
    
    rel = [] # an array of array of hashes created by model.as_json from the not empty sets
    sets.each do |m|
      m_name = m.class.name
      case m_name
      when 'Tag'
        rel += [tag_hash(m)] unless m.nil?
      when 'Value'
        rel += [value_hash(m)] unless m.nil?
      else
        logger.debug "DID YOU MISS A CONDITION IN tuple_relations #{m.inspect}"
      end
    end
    return rel
  end
  
# HASH METHODS
  def subject_hash(subject,wrap=true)
    hash = subject.as_json(:except => [:created_at, :updated_at ], 
      :include => {:tags => {:except => [:created_at, :updated_at ], :methods => :values,
      :include => {:value => {:except => [:created_at, :updated_at ]}}}})
    if wrap
      result = {:subject => hash}
    else
      result = hash
    end
  end
  
  # TODO Can't have multiple subjects?, get rid of this if a use not found
  def subjects_hash(subjects,wrap=true) 
    relations = []
    subjects.each do |subject|
      relations << subject_hash(subject,false)
    end
    if wrap
      result = {:subjects => relations}
    else
      result = relations
    end
  end
  
  
  def tag_hash(tag,wrap=true)
    hash = tag.as_json(:except => [:created_at, :updated_at ], :method => :siblings,
      :include => {:subject =>  {:except => [:created_at, :updated_at ]}, 
      :value =>  {:except => [:created_at, :updated_at ]}})
    values = Value.where(:id => tag.siblings).as_json(:except => [:created_at, :updated_at ])
    hash[:values] = values
    # hash[:tag]['siblings'] = siblings
    if wrap
      result = {:tag => hash}
    else
      result = hash
    end
  end
  
  def tags_hash(tags,wrap=true)
    relations = []
    tags.each do |tag|
      relations << tag_hash(tag,false)
    end
    if wrap
      result = {:tags => relations}
    else
      result = relations
    end
  end
  
  def value_hash(value,wrap=true)
    hash = value.as_json(:except => [:created_at, :updated_at ],
      :include => {:subject =>  {:except => [:created_at, :updated_at ]}, 
      :tags =>  {:except => [:created_at, :updated_at ]}})
    if wrap
      result = {:value => hash}
    else
      result = hash
    end
  end
  
  def values_hash(values,wrap=true)
    relations = []
    values.each do |value|
      relations << value_hash(value,false)
    end
    if wrap
      result = {:values => relations}
    else
      result = relations
    end
  end
  
  def tuple
    return @tuple
  end
  
  def tuple_hash
    s = t = v = nil
    sh = th = vh = {}
    if @tuple[:subject][:has]
      s = Subject.find(@tuple[:subject][:id])
      sh = s.as_json(:except => [:created_at, :updated_at ])
      if @tuple[:tag][:has]
        t = Tag.where(:id => @tuple[:tag][:id])
        th = t.as_json(:except => [:created_at, :updated_at ])
        if @tuple[:value][:has]
          v = Value.where(:id => @tuple[:tag][:id])
          vh = v.as_json(:except => [:created_at, :updated_at ])
        end
      end
    end
    sh[:tags] = th
    sh[:values] = vh
    return {:subject => sh}
  end
    

# MODEL METHODS
  def new_tuple
    return Subject.new_tuple(response['subject'],response['tag'],response['value'],response['info'])
  end

  def new_relation
    relations = response['relations']
    results = []
    relations.each do |r|
      t = r['tuple']
      unless t['subject']['has']
        result = Subject.new_tuple(r['subject'], r['tag'],r['value'])
      else
        subject = Subject.find(t['subject']['id'])
        unless t['tag']['has']
          result = subject.new_tag_and_value(r['tag'],r['value'])
        else
          tag = Tag.find(t['tag']['id'].first)
          result = tag.append_value(r['value'])
        end
      end
      results += result
    end
    return results[0] && results[1], { :message => "Tried stuffing, indexing, green good, red bad"}
  end
    
  def new_tag_and_value
    subject = Subject.find(response['subject_id'])
    if subject.nil?
      return false,  { :message => "Whoa's is me. I could not find that subject"}
    else
      return subject.new_tag_and_value(response['tag'],response['value'],response['info'])
    end
  end
  
  def append_value
    tag = Tag.find(response['tag_id']).first #all tag id with same name come in to response
    if tag.nil?
      return false,  { :message => "Whoa's is me. I could not find that tag"}
    else
      return tag.append_value(response['value'],response['info'])
    end
  end
  
  def change_value(params)
    value = Value.find(response['value_id'])
    if value.nil?
      return false,  { :message => "Whoa's is me. I could not find that value"}
    else
      value.name = params[:name]
      value.info = params[:info]
      if value.save
        return true, { :message => "Stuffing..., Indexing - Got it"}
      else
        return false, {:message => "Whoops, I had a problem saving the new values"}
      end
    end
  end
  
  private
  
  def get_command_and_query(str)
    qstr = str.strip
    # See if there is an command, most not needed
    command = ""
    has_command = str.match(/(what's|who's|forget's|change's|new's|relate's)/i)
    if has_command 
      command = has_command[0].gsub(/'(s|t)/,"") 
      qstr = str.gsub(/#{has_command[0]}/i,"")
    end
    
    return command, qstr
  end
  
  def get_info(qstr)
    info = ""
    if qstr.include?("::")
      chunks = qstr.split("::")
      qstr = chunks[0]
      info = chunks[1]
      if chunks.size > 2
        info = info + "::" + chunks[2..-1].join('::')
      end
    end
    @info = info
    return info
  end
  
  def get_subject_tag_value(qstr)
    # get the attributes
    subject = tag = value = target = 
    dots = qstr.scan(/\w\.\w/)
    if dots.empty?
      words = qstr.split
    else
      words = qstr.split('.')
    end
    subject = tag = value = ""
    case words.size
    when 1
      subject = words[0].gsub("'s","").strip
      target = 'subject'
    when 2
      subject = words[0].gsub("'s","").strip
      tag = words[1].gsub("'s","").strip
      target = 'tag'
    else
      subject = words[0].gsub("'s","").strip
      tag = words[1].gsub("'s","").strip
      value = words[2..-1].join(" ").strip
      target = 'value'
    end
    self.subject = subject
    self.tag = tag
    self.value = value
    self.target = target
    return subject,tag,value, target
  end
  
  def reset_tuple
    tuple = {
      subject: {has: false, id: nil},
      tag: {has: false, id: nil},
      value: {has: false, id: nil}
    }
  end
  
end
