user = Forem.user_class.first
unless user.nil?
  category = Forem::Forum.find_or_create_by(:name => "Group")
  category2 = Forem::Forum.find_or_create_by(:name => "Open Forum")
  
  forum = Forem::Forum.find_or_create_by( :category_id => Forem::Category.first.id, 
                               :title => "Default",
                               :description => "Default forem created by install")
  topic = Forem::Topic.find_or_create_by( :forum_id => forum.id,
                               :user_id => user.id, 
                               :subject => "Welcome to forem!", 
                               :posts_attributes => [{:text => "Hello World", :user_id => user.id}])
  topic.posts.first.save!
end