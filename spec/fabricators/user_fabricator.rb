Fabricator(:user) do
  login 'forem_user'
  email { "bob#{rand(100000)}@boblaw.com" }
  password 'password'
  password_confirmation 'password'
end

Fabricator(:admin, from: :user) do
  forem_admin true
end
