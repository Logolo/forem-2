module Forem
  class CategoriesController < Forem::ApplicationController
    def show
      @category = Forem::Category.find(params[:id])
    end
  end
end
