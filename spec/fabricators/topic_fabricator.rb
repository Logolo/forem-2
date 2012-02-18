Fabricator(:topic, class_name: 'Forem::Topic') do
  subject 'FIRST TOPIC'
  forum
  user
  posts { |t| [Fabricate(:post, topic: t)] }
end
