class Group
  include Mongoid::Document
  include ActiveModel::SecurePassword
  include Mongoid::Token

  token  :length => 5, :contains => :alphanumeric

  class Group::BannerUploader < CarrierWave::Uploader::Base
  end

  field :name
  field :description
  field :commissioner_id, type: BSON::ObjectId
  field :password_digest
  field :is_public, type: Boolean, default: false
  embeds_many :members, class_name: 'GroupMembership'
  mount_uploader :banner, BannerUploader

  attr_accessor :tos

  has_secure_password

  validates :name, presence: true
  validates :commissioner_id, presence: true
  validates :tos, acceptance: true
  validates :password, presence: true, on: :create, unless: :is_public

  before_create :add_commissioner_as_member

  class << self
    def find_by_commissioner(id)
      where(commissioner_id: id)
    end
  end

  def commissioner?(user)
    member = self.members.where(user_id: user.id).first
    return member && member.commissioner?
  end

  private

  def add_commissioner_as_member
    self.members.build(user_id: self.commissioner_id)  
  end
end
