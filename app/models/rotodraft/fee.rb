
class Fee
  include Mongoid::Document
  include Mongoid::Token

  token :length => 2
  
  field :entry_fee, :type => Integer, :index => true #in cents; TODO Attempt to use mongoid_money type
  field :ifs_fee_usd, :type => Integer #in cents
  field :currency, :type => String
  field :is_default, :type => Boolean
  
  # References
  has_many :drafts
  
  validates :entry_fee, :presence => true, :numericality => { :greater_than_or_equal_to => 0 }
  validates_uniqueness_of :entry_fee,  :message => "must be unique"
  validates :ifs_fee_usd, :presence => true, :unless => "entry_fee == 0"
  validates :ifs_fee_usd, :numericality => { :greater_than => 0, :less_than => :entry_fee }, :unless => "entry_fee == 0"
  validates :currency, :presence => true, :format => { :with => /^USD$/ }
  validates_uniqueness_of :is_default,  :message => "must be unique", :allow_nil => true
  
  def fee_in_dollars
    dollars = (self.entry_fee / 100).to_f
    sprintf('%.02f', dollars)
  end
end
