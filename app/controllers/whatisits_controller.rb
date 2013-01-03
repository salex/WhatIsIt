class WhatisitsController < ApplicationController

  def index  
    @subjects = Subject.order(:name).pluck(:name)  
    @tags = Tag.order(:name).uniq(:name).pluck(:name)  
    @values = Value.order(:name).uniq(:name).pluck(:name)  
  end
  
  def query
    @what = What.new
    @what.response = @what.query(params[:query])
    logger.debug "RESP #{@what.inspect}"
    respond_to do |format|
      if @what.response[:error] || @what.response[:debug]  
        if @what.response[:error]
          format.html { redirect_to root_path, alert:  @what.response[:error][:message] }
        else
          format.html { redirect_to root_path, alert:  @what.response[:debug].inspect }
        end
      else
        format.html 
      end
    end
  end
  
  def forget
    resources = (params[:id].capitalize.constantize).find(params[:delete][:id])
    puts "DELETE ALL  #{resources.inspect}"
    if resources.class == Array
      result = resources.each(&:destroy)
    else
      result = resources.destroy
    end
    respond_to do |format|
      if result
        format.html {redirect_to root_path, :notice => "Selected #{params[:id]} and any associations deleted."}
      else
        format.html {redirect_to root_path, :alert => "Whoa's if me. Deleting #{params[:id]} and any associations FAILED."}
      end
    end
  end
  
  def subject
    @subject = Subject.find(params[:id])
    @what = What.new
    @what.response = @what.subject_hash(@subject)
    @what.target = 'change_subject'
    
    respond_to do |format|
      format.js {render  'edited'}
    end
  end
  
  def tag
    @tag = Tag.find(params[:id])
    @what = What.new
    @what.response = @what.tag_hash(@tag)
    @what.target = 'change_tag'
    
    respond_to do |format|
      format.js {render  'edited'}
    end
  end
  def value
    @value = Value.find(params[:id])
    @what = What.new
    @what.response = @what.value_hash(@value)
    @what.target = 'change_value'
    respond_to do |format|
      format.js {render  'edited'}
    end
  end
  def update_model
    if params[:edited][:model] == 'Value'
      value = Value.find(params[:id])
      value.name =  params[:edited][:name]
      value.info =  params[:edited][:info]
      results = value.save
      if results
        message = "Stuffing..., Indexing - Got it. Value updated"
      else
        message = "Opps, something in updating the Value failed"
      end
    elsif params[:edited][:model] == 'Tag'
      tag = Tag.find(params[:id])
      tag.name =  params[:edited][:name]
      results = tag.save
      if results
        message = "Stuffing..., Indexing - Got it. Value updated"
      else
        message = "Opps, something in updating the Tag failed"
      end
      
    elsif params[:edited][:model] == 'Subject'
      subject = Subject.find(params[:id])
      subject.name =  params[:edited][:name]
      results = subject.save
      if results
        message = "Stuffing..., Indexing - Got it. Subject updated"
      else
        message = "Opps, something in updating the Subject failed, probably a duplicate name."
      end
      
    else
    end
    if results
      redirect_to root_path, :notice => message
    else
      redirect_to root_path, :alert => message
    end
  end
  
  def update
    @what = What.new
    @what.response = JSON.parse params[:response]
    result = "none"
    message = nil
    case params['edit'].keys[0]
      when 'new_tuple'
        if params[:edit]['new_tuple'] == 'true'
          results, message  = @what.new_tuple
        else
          message = 'Okay, no new subject, tag and value. ' 
        end
      
      when 'new_tag_and_value'
        if params[:edit]['new_tag_and_value'] == 'true'
          results, message  = @what.new_tag_and_value
        else
          message = 'Okay, no new tag and value. ' 
        end
      when 'change_value'
        if params[:edit]['change_value'] == 'true'
          results, message  = @what.change_value(params[:edited])
        else
          message = 'Okay, no new value. ' 
        end
      
  
      when 'append_value'
        if params[:edit]['append_value'] == 'true'
          results, message  = @what.append_value
        else
          message = 'Okay, no new value. ' 
        end
      else        
        message = 'Whoops in append_value. ' 
    end
    if message.class == Hash
      message = message[:message]
    end
    if results
      redirect_to root_path, :notice => message
    else
      redirect_to root_path, :alert => message
    end
  end
end