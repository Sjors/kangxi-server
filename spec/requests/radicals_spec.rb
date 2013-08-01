require 'spec_helper'
include Helpers

describe "Radicals" do
  it "goes to list of radicals from main screen" do
    FactoryGirl.create(:radical, :simplified => "人")
    visit "/"
    click_link "Radicals"
    page.should have_content "人"
  end
  
  describe "Add radical" do
    it "adds a radical" do
      
      visit new_radical_path
      fill_in "Simplified", :with => "人"
      fill_in "Position", :with => "9"
      click_button "Create Radical"
          
      page.should have_content("人")
    end
  end
end
