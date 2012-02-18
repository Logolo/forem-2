# coding: utf-8

class User
  include Mongoid::Document
  include Mongoid::MultiParameterAttributes
  include Sorcery::Model
  include Sorcery::Model::Adapters::Mongoid
  include Mongoid::Token
  authenticates_with_sorcery!

  after_initialize :default_privacy
  after_initialize :default_team

  attr_accessible :email, :password, :password_confirmation, :first_name, :last_name,
  :street_address, :city, :state, :zip, :region, :mobile_phone, :home_phone,
  :date_of_birth, :gender, :username, :heard_from, :tos

  token  :length => 5, :contains => :alphanumeric

  field :first_name
  field :last_name
  field :street_address
  field :city
  field :state
  field :zip
  field :region
  field :mobile_phone
  field :home_phone
  field :date_of_birth, :type => Date
  field :gender
  field :username
  field :heard_from
  field :tos
  field :forem_admin, :type => Boolean, :default => false

  # Relations
  has_one  :team
  has_many :roster_requirements, :as => :creator #TODO: These polymorphic definitions are broken.
  has_many :scoring_systems, :as => :creator #TODO: These polymorphic definitions are broken.
  has_many :drafts, :as => :creator #TODO: These polymorphic definitions are broken.
  has_many :buddies, class_name: 'BuddyRelationship'
  embeds_one :privacy

  # from http://www.gregwillits.ws/articles/custom-validation-in-rails#utf8 to allow most UTF-8 characters
  name_regex = /^[ a-zA-Z0-9#{"\303\200"}-#{"\303\226"}#{"\303\231"}-#{"\303\266"}#{"\303\271"}-#{"\303\277"}\_]*?$/u

  validates :email,           :presence => true,
  :format => { :with => /\A[^@]+@([^@\.]+\.)+[^@\.]+\z/ },
  :uniqueness => true

  validates :password,        :on => :create, :presence => true,
  :confirmation => true if :password

  validates :first_name,      :presence => true,
  :length => { :maximum => 50 },
  :format => { :with => name_regex }

  validates :last_name,       :presence => true,
  :length => { :maximum => 50 },
  :format => { :with => name_regex }

  validates :username,        :presence => true,
  :length => { :maximum => 20 }

  validates_with              ProfanityValidator

  validates_format_of         :mobile_phone, :home_phone,
  :with => /^[\(\)0-9\- \+\.]{10,20}$/,
  :allow_blank => true

  validates_presence_of       :date_of_birth

  validates_acceptance_of     :tos, :allow_nil => false, :on => :create

  validates :street_address,  :presence => true, :length => { :maximum => 50 }
  validates :city,            :presence => true, :length => { :maximum => 50 }
  validates :state,           :presence => true
  validates :region,          :presence => true
  validates :zip,             :presence => true,
  :length => { :maximum => 10 },
  :format => { :with => /^\d{5}-\d{4}|\d{5}|[A-Z]\d[A-Z] \d[A-Z]\d$/ }

  accepts_nested_attributes_for :team

  def messages
    Message.where(to_user_id: self.id)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def abbreviated_name
    "#{first_name} #{last_name[0].chr}."
  end

  def buddy_requests
    self.buddies.where(status: 'requested')
  end

  def buddy_request_count
    self.buddy_requests.count
  end

  def buddies_with?(user)
    self.buddies.where(buddy_id: user.id).any? ||
    user.buddies.where(buddy_id: self.id).any?
  end

  def request_buddy!(user)
    self.buddies.create!(buddy_id: user.id, status: 'pending')
    user.buddies.create!(buddy_id: self.id, status: 'requested')
  end

  def accept_buddy!(buddy_relationship_id)
    my_side = self.buddies.find(buddy_relationship_id)
    their_side = User.find(my_side.buddy_id).buddies.where(buddy_id: self.id).first

    [my_side, their_side].each do |side|
      side.update_attributes!(status: 'accepted')
    end
  end

  def find_buddy_relationship(user_id)
    self.buddies.where(buddy_id: user_id).first
  end

  def commissioned_groups
    Group.find_by_commissioner(self.id)
  end

  def group_memberships
    Group.where("members.user_id" => self.id)
  end

  def group_invitations
    GroupInvitation.where(:user_id => self.id)
  end

  def drafts_joined
    team.drafts
  end

  private

  def default_privacy
    self.build_privacy if self.privacy.nil?
  end

  def default_team
    self.build_team if self.team.nil?
  end
end
