user = Forem.user_class.first
unless user.nil?
  category = Forem::Forum.find_or_create_by(:name => "Group")
  category2 = Forem::Forum.find_or_create_by(:name => "Open Forum")

  forum = Forem::Forum.find_or_create_by( :category_id => Forem::Category.first.id,
                               :title => "Default",
                               :description => "Default forem created by install")

  post = Forem::Post.find_or_initialize_by_text("Hello World")
  post.user = user

  topic = Forem::Topic.find_or_initialize_by_subject("Welcome to Forem")
  topic.forum = forum
  topic.user = user
  topic.posts = [ post ]

  topic.save!
end
