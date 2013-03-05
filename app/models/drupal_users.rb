class DrupalUsers < ActiveRecord::Base
  # attr_accessible :title, :body
  self.table_name = 'users'
  self.primary_key = 'uid'

  has_many :drupal_node, :foreign_key => 'uid'
  has_many :drupal_profile_values, :foreign_key => 'uid'

  def created_at
    Time.at(self.created)
  end

  def profile_values
    self.drupal_profile_values
  end

  def location
    DrupalProfileValue.find_by_uid(self.uid, :conditions => {:fid => 2}).value
  end

  def bio
    bio = DrupalProfileValue.find_by_uid(self.uid, :conditions => {:fid => 7})
    if bio
      bio.value 
    else
      ""
    end
  end

  def notes
    DrupalNode.find_all_by_uid self.uid
  end

  # accepts array of tag names (strings)
  def notes_for_tags(tagnames)
    all_nodes = DrupalNode.find(:all,:order => "nid DESC", :conditions => {:type => 'note', :status => 1, :uid => self.uid})
    node_ids = []
    all_nodes.each do |node|
      node.tags.each do |tag|
        tagnames.each do |tagname|
          node_ids << node.nid if tag.name == tagname
        end
      end
    end
    DrupalNode.find(node_ids.uniq, :order => "nid DESC")
  end

  def tags
    tags = []
    DrupalNode.find(:all,:order => "nid DESC", :conditions => {:type => 'note', :status => 1, :uid => self.uid}, :limit => 20).each do |node|
      tags += node.tags
    end
    tags.uniq
  end

  def tag_counts
    tags = {}
    DrupalNode.find(:all,:order => "nid DESC", :conditions => {:type => 'note', :status => 1, :uid => self.uid}, :limit => 20).each do |node|
      node.tags.each do |tag|
        if tags[tag.name]
          tags[tag.name] += 1
        else
          tags[tag.name] = 1
        end
      end
    end
    tags
  end

  def self.locations
    DrupalUsers.find(:all, :conditions => ["profile_values.fid = 2 AND profile_values.value != ''"], :include => :drupal_profile_values)
  end

  def geocode

    location = Geokit::Geocoders::MultiGeocoder.geocode(self.location)
    if location
      self.lon =  location.lng
      self.lat =  location.lat
      self.save!
    else
      return false
    end
  end

end