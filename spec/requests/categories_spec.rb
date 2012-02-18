require 'spec_helper'

describe 'categories' do
  let!(:category_1) { Factory(:category) }
  let!(:forum_1) { Factory(:forum, :category => category_1, :title => "Category 1 Forum") }

  let!(:category_2) { Factory(:category) }
  let!(:forum_2) { Factory(:forum, :category => category_2, :title => "Category 2 Forum") }

  it "sees categorised forums" do
    visit forums_path
    within("#category_#{category_1.id}") do
      page.should have_content(forum_1.title)
    end

    within("#category_#{category_2.id}") do
      page.should have_content(forum_2.title)
    end
  end

  it "can view a category's forums" do
    visit forums_path
    click_link category_1.name
    page.should have_content(forum_1.title)
    page.should_not have_content(forum_2.title)
  end
end
