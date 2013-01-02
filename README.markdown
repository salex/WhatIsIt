### WhatIsIt

WHATSIT was a command line database I first saw at the 1978 West Coast Computer Fair. I think I actually bought it and was
amazed by what it could do. I had made several attempts over the years to replicate it, but only got so far. I decided to make another 
attempt using RoR. I still remember typing in a command, listening the disk spin and grind and spit out the information. I can't find 
much on it on the web, but found this 
<a href="http://www.moofgroup.com/moof/Roby_Sherman/Adventures_in_Silicon/Entries/2006/12/27_Wow!_Howd_All_That_Stuff_Get_In_There.html">
link</a> that display what the command line interaction looked like. This was 1978 and we were still in COBOL index sequential days. Relational databases only
lived on DEC equipment and not very prevalent. I know all the disk crunching and grinding was some custom indexing, but being build in basic (maybe some assembler) on and Apple II or CPM system, was impressive.



It was just one of many "Index Card" type applications of the time. It was meant for you to store your important information if it conformed to a Subject, Tag, Value type system. It was really a dynamic hash:

    {:subjects=>[
      {:name=>"x", 
      :tags=>[{:name=>"y", :values=>[{:name=>"z"}, {:name=>"zz"}]},
        {:name=>"y1", :values=>[{:name=>"z"}, {:name=>"zz"}]
      }]}
    ]}
    
It was not meant as a group database, but just someplace to put your stuff. WhatIsIt is not different.

I was going to attempt the command line interaction using AJAX and javascript, but chickened out. What I came up with is close. The submit button is
grayed out, but usable (or just use the Return key in the search field). 
I added radio buttons instead of a text box for the Yes/No inputs..



### Interface!

<fieldset>
<a href="/">Home</a>
<h5>
WhatIsIt?
</h5>
<input autofocus="autofocus" id="query" name="query" size="50" type="search" value="steve" />
<input class="dim" name="commit" type="submit" value="WhatIsIt?" />
</fieldset>

There are only few commands: What's, Who's, New's and Forget's. Forget's is the only one required, it can figure out what you meant without the command!
The database has three
models: Subject->Tag<-Value (S/T/V). Subject and Tab attribute name must not contain spaces, use underscores. Value is wide open. The Subject name is forced to unique.
I took some liberty with the commands:

  * What's Steve's Phone's is the same as Steve's Phone's or just drop the 's and use Steve phone. 
  * Who's dumps a Subject, but just typing the subject name will do the same
  * You can add a new relation by simple typing three or more words: Steve Phone Home::256-467-4348
  * The double colon allows you to add more information to the value. If you modify the Value, you can actually add other attributes
  * Typing three words that match S/T/V will allow you to change the Value
  * Typing two words that match S/T and a third word that does not match V, will allow to append a new Value using the same Tag
  * All searches use ILIKE with a '%' wild card. StE% will find Steve. Classic wild cards: word% = starts with, %word% = contains, %word = ends with
  * Typing one word will look for that name in all models.
  * Typing two words will first look for Subject/Tag and if not found will look at all the relations: Phone Home will find anyones home phone.

Steve Wanda% will find Steve's mother if Mother is the tag that links Steve to Wanda P Hrobak 

 

### This was just an experiment to do some stuff in a non-CRUD database.  The three models header infomration:

    class Subject < ActiveRecord::Base
      has_many :tags, :dependent => :destroy
      has_many :values, :through => :tags
      validates_presence_of :name
      validates_uniqueness_of :name, :case_sensitive => false
    end

    class Tag < ActiveRecord::Base
      belongs_to :subject
      belongs_to :value, :dependent => :destroy
      validates_presence_of :name
    end

    class Value < ActiveRecord::Base
      has_many :tags
      has_many :subjects, :through => :tags
      store :info, :assessors => :info
    end
    
I did generate a Subject scaffold by don't use it. The majority of the code is in a class What. The main methods are

* query - receive a command string from the search box and parses in into command, subject, tag, and value
  * It is really the controller for the application and is called by the whatisit_controller
  * The query string is evaluated for the action command: query, append_value, forget, change, assign which are just forms of index,show,new,update,edit and destroy.
  * The action command then return the results in a hash that contains what was found in as a as_json hash.
  * Helper methods build the queries based on Who, What and Related type queries. Then call _hash routines depending on the controlling model(s)
  * The whatisit controller then calls display or edit pages.
* Update routines are new_tuple, append_value, append_tag_and_value and change_value that interact with the models

### Things WHATSIT didn't do (or I can't remember)

* Or queries  `steve phone home|work`
* Wildcard queries. All queries is Postgresql ILIKE so `st%` will query any subject that starts with "st"
* related queries. If only two word are supplied and a subject, tag is not found, it will look for relations between subject and value and value and tag in any order
* All display pages have links to modify subject, tag or value.  Change is not implemented at this time except through these links.

The current commands are: (the method that determines them)

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

Again, change and relate are still in the think stage.

An example of a _hash method

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
    
An example of a query helper:

    def who_s_value(subject,tag,value)
      v_ilike = @tuple[:value][:ilike] ||= ['values.name ilike ?',value]
      t_ilike = @tuple[:tag][:ilike] ||= ['tags.name ilike ?',tag]
      s_ilike = @tuple[:subject][:ilike] ||= ['subjects.name ilike ?',tag]
      v = Value.where(v_ilike).joins(:subjects) 
      v = v.joins(:subjects).where(s_ilike)
      v = v.joins(:tags).where(t_ilike)
      if v.count < 2
        hash = value_hash(v)
      else
        hash = values_hash(v)
      end
    end

_@tuple contains basic information on the serach, if it was found, the id and optional ilike tag if the search field had a |_


### That's What's it is.  WIP and don't think it has any life other than for me to experiment with.