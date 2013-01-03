module SubjectsHelper
  def value_link(value)
    return (link_to raw("&#187;"), value_whatisit_path(value["id"]), :'data-remote' => true) + " #{value['name']}"
  end
  
  def tag_link(tag)
    return (link_to raw("&#187;"), tag_whatisit_path(tag["id"]), :'data-remote' => true) + " #{tag['name']}"
  end
  
  def subject_link(subject)
    return ((link_to raw("&#187;"), subject_whatisit_path(subject["id"]), :'data-remote' => true) + " #{subject['name']}").html_safe
  end
  
  def subject_query(subject)
    raw(link_to subject["name"], query_whatisits_path(:query => subject["name"]))
  end
  def value_query(value)
    raw(link_to value["name"], query_whatisits_path(:query => value["name"]))
  end
  def tag_query(tag)
    raw(link_to tag["name"], query_whatisits_path(:query => tag["name"]))
  end
  #==================subject, tag and value renders
  #++++++++++++++++++
  def render_subject(subject,tag=nil)
    # li if tag or p if not
    if tag
      html = "<h5>It be's #{subject_link(subject)}'s #{tag_link(tag)}</h5>\n"
    else
      html = "<h5>Who be's #{subject_link(subject)}</h5>\n"
    end
    return html.html_safe
  end
  
  def render_tag_and_values(values,tag)
    html = "<li><strong>#{tag_link(tag)}</strong>\n"
    html << "<ul>\n"
    values.each do |value|
      html << "<li><strong>#{value_link(value)}</strong>\n"
      value["info"].each do |k,v|
        html << "<ul><li>  #{k}: #{v}</li></ul>\n"
      end
    end
    html << "</li></ul>\n"
    return html.html_safe
  end
  
  def render_tag_and_value(subject,tag,value=nil)
    html = "<li><strong> #{subject_link(subject)}'s #{tag_link(tag)}</strong>\n"
    value = tag[:value] ||= value
    html << "<ul>"
    html << "<li><strong>#{value_link(value)}</strong>\n"
    value["info"].each do |k,v|
      html << "<ul><li>  #{k}: #{v}</li></ul></li>\n"
    end
    html << "</ul>\n"
    return html.html_safe
  end
  
  def subject_root(subject)
    html = ""
    tags = subject[:tags]
    html << render_subject(subject)
    html << "<ul>\n"
    tag_array = []
    tags.each do |tag|
      if tag[:values]
        if !tag_array.include?(tag["name"])
          values = tag[:values]
          tag_array << tag["name"]
          html << render_tag_and_values(values,tag)
        end
      else
        html << render_tag_and_value(subject,tag)
      end
    end
    html << "</ul>\n"
    return html.html_safe
  end
  
  def tag_root(tag)
    subject = tag[:subject]
    html = render_subject(subject,tag)
    html << raw("<ul>\n")
    
    if tag[:values]
      values = tag[:values]
      html << render_tag_and_values(values,tag)
    else
      html << render_tag_and_value(subject,tag)
    end
    html << raw("</ul>\n")
    
    return html.html_safe
  end
  
  def tags_root(tags)
    html = ""
    tag_array = []
    tags.each do |tag|
      if tag[:values]
        key = tag['name']+"_"+tag[:subject]["name"]
        if !tag_array.include?(key)
          tag_array << key
          html << tag_root(tag)
        end
      else
        html << tag_root(tag)
      end
    end
    return html.html_safe
  end
  
  
  def values_root(values)
    html = ""
    values.each do |value|
      html << value_root(value)
    end
    return raw(html)
  end
  
  def value_root(value)
    html = ""
    if value[:tags]
      html << "<h5>It be the <i>Value</i> #{value_link(value)}: for  #{subject_link(value[:subject])}</h5>"
      value[:tags].each do |tag|
        html << '<ul>'
        html << render_tag_and_value(value[:subject],tag,value)
        html <<"</ul>"
      end
      
    else
      html << "GESSS i need to find this"
    end
    return raw(html)
  end


  # def render_values(values)
  #   # if values.class == Hash
  #   #   values = [values]
  #   # end
  #   html = ""
  #   values.each do |value|
  #     html <<  <<-HERE
  #     <h5>
  #      render_values It Be  => 
  #       #{(subject_link(value[:subject]) + "'s")}
  #     </h5>
  #     HERE
  #     if value[:tags]
  #       value[:tags].each do |tag|
  #         html <<  <<-HERE
  #         <ul><li><strong>MMMMMM #{tag_link(tag)}</strong></li>
  #           #{render_value(value)}
  #         </ul>
  #         HERE
  #       end
  #     else
  #       html <<  <<-HERE
  #       OOOOOOO
  #       #{tag_link(value[:tag])}
  #       #{render_value(value)}
  #       HERE
  #     end
  #   end
  #   return html.html_safe
  # end
  # 
  # def render_tags(tags)
  #   if tags.class == Hash
  #     tags = [tags]
  #   end
  #   html = ""
  #   tags.each do |tag|
  #     html <<  <<-HERE
  #     <h5>
  #       It Be  => 
  #       #{(subject_link(tag[:subject]) + "'s")}
  #       #{tag_link(tag)}
  #       
  #     </h5>
  #     HERE
  #     if tag[:values]
  #       tag[:values].each do |value|
  #         html <<  render_value(value)
  #       end
  #     else
  #       html << render_value(tag[:value])
  #     end
  #   end
  #   return html.html_safe
  # end
  # 
  # def render_tag(tags)
  #   html = ""
  #   tag = tags.first
  #   html <<  <<-HERE
  #   <h5>
  #     It Be  => 
  #     #{(subject_link(tag[:subject]) + "'s")}
  #     #{tag_link(tag)}
  #     
  #   </h5>
  #   HERE
  #   if tag[:values]
  #     tag[:values].each do |value|
  #       html <<  render_value(value)
  #     end
  #   else
  #     html << render_value(tag[:value])
  #   end
  #   return html.html_safe
  # end
  # 
  # def render_subjects(subjects)
  #   html = ""
  #   subjects.each do |subject|
  #     html <<  <<-HERE
  #     <h5>
  #       It Be a Subject => 
  #       #{subject_link(subject)}
  #     </h5>
  #     HERE
  #     subject[:tags].each do |tag|
  #       html <<  <<-HERE
  #       <ul>
  #         <li>
  #           <strong>#{(tag_link(tag) + "'s")}</strong>
  #         </li>
  #         #{render_value(tag[:value])}
  #       </ul>
  #       HERE
  #     end
  #   end
  #   return html.html_safe
  # end
  # 
  # def render_value(value)
  #   html = ""
  #  html <<  <<-HERE
  #   <ul>
  #     <li>#{value_link(value)} 
  #     <ul>
  #   HERE
  #   value["info"].each do |k,v|
  #     html <<  <<-HERE
  #       <li>
  #         #{k}: #{v}
  #       </li>
  #     HERE
  #   end
  #   html << '</ul></ul>'
  #   return html.html_safe
  # end
  # 
end # module end




# subjects
#   
#   render_subject(s) 
#   tags.each do |t|
#     if t[:values]
#       render_values(t,v)
#     else
#       render_value(t,v)
#     end
#   end
# end
# 
# tags.each do |t|
#   s = t.subject
#   if t[:values]
#     render_subject(s,t) 
#     render_values(t,v)
#   else
#     render_subject(s,t) 
#     render_value(t,v)
#   end
# end
# 
# values.each do |v|
#   s = v.subject
#   t = v.tags
#   if t[:values]
#     render_subject(s,t) 
#     render_values(t,v)
#   else
#     render_subject(s,t) 
#     render_value(t,v)
#   end
# end
  