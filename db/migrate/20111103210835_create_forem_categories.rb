class CreateForemCategories < ActiveRecord::Migration
  def change
    Forem::Category.create(:name => 'General')
  end
end
