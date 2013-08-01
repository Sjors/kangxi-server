require 'spec_helper'
include Helpers

describe "Characters" do
  it "goes to list of characters from main screen" do
    FactoryGirl.create(:character, :simplified => "人")
    visit "/"
    click_link "Characters"
    page.should have_content "人"
  end
  
  describe "Add character" do
    it "adds a character and allows another to be added" do
      
      visit new_character_path
      fill_in "Simplified", :with => "人"
      click_button "Create Character"
      
      page.should have_content("Successfully")
      
      page.should have_content("Simplified")
    end
  end
end
