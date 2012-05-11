module Forem
  module Autocomplete
    def forem_autocomplete(term)
      where("#{Forem.autocomplete_field}" => /#{term}/).
      limit(10).
      to_a
    end

  end
end
