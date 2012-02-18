class AddForemAdmin < ActiveRecord::Migration

  def change
<<<<<<< HEAD
#    add_column <%= user_class.constantize.table_name.to_sym.inspect %>, :forem_admin, :boolean, :default => false
=======
    add_column <%= user_class.constantize.table_name.to_sym.inspect %>, :forem_admin, :boolean, :default => false
>>>>>>> 5e3a14171f1940f9bbefd74f58ec546ca692d263
  end
end
