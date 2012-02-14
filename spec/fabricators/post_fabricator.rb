Fabricator(:post, class_name: 'Forem::Post') do
  text 'This is a brand new post!'
  user
  topic
end
