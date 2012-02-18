class PrizeDistributionShouldNotExceedPrizePool < ActiveModel::Validator
  def validate(record)
    if prize_distribution_exceeds_prize_pool?(record)
    record.errors[:base] << "Attempt to add more prizes to positions than there is money in the prize pool"
    puts "Errors inside:" + record.errors.inspect
    end
  end

  private

  def prize_distribution_exceeds_prize_pool?(record)
    puts "Inspect: " + record.inspect
    if !record[:prize_distribution_attributes].nil?
    puts "Validation: " + record.prize_distributions.sum(:prize_in_cents).to_s + " Pool: " + record.prize_pool.to_s
    return (record.prize_distributions.sum(:prize_in_cents) > record.prize_pool)
    end
  end

end

class Prize
  include Mongoid::Document

  # Fields
  field :prize_pool, :type => Integer # in cents

  # Embeds
  embeds_many :prize_distributions
  #  accepts_nested_attributes_for :prize_distributions, :reject_if => :reject_prizes
  accepts_nested_attributes_for :prize_distributions

  validates :prize_pool, :presence => true
  validates_numericality_of :prize_pool, :greater_than_or_equal_to => 0
  #  validates_with PrizeDistributionShouldNotExceedPrizePool
  def reject_prizes(value)
    running_prize_total = 0
    self.prize_distributions.all.each do |distribution|
      running_prize_total += distribution.prize_in_cents
    end
    puts "Global validation " + running_prize_total.to_s + "+" + value[:prize_in_cents].to_s + ">" + self.prize_pool.to_s
    if ((running_prize_total + value[:prize_in_cents]) > self.prize_pool ) then
    @distribution_too_large_error = "Attempt to add more prizes to positions than there is money in the prize pool"
    end

    return (running_prize_total + value[:prize_in_cents]) > self.prize_pool
  end

end

