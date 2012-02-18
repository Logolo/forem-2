class PrizeDistribution
  include Mongoid::Document

  # Fields
  field :place, :type => Integer
  field :prize_in_cents, :type => Integer

  # Embeds
  embedded_in :prize, :inverse_of => :prize_distributions

  validates :place, :presence => true
  validates_uniqueness_of :place
  validates_numericality_of :place, :greater_than => 0
  
  # ensure places represent a continuous range
  validates_each :place do |record, attr, value|
    if !record.prize.nil? then
      min = record.prize.prize_distributions.min(attr)
      max = record.prize.prize_distributions.max(attr)
      total_places = record.prize.prize_distributions.where(attr.gt => 0).count
      record.errors.add attr, "Attempt to add prize distribution with discontinuous prize positions." if (min..max) === value && total_places != max
    end        
  end
  

  validates :prize_in_cents, :presence => true
  validates_numericality_of :prize_in_cents, :greater_than => 0
  
  # ensure prize distribution does not exceed prize pool
  validates_each :prize_in_cents do |record, attr, value| 
    if !record.prize.nil? then
      record.errors.add attr, "Attempt to add prize distribution that exceeds prize pool of #{record.prize.prize_pool}." if ( record.prize.prize_distributions.sum(attr) > record.prize.prize_pool)
    end    
  end

end