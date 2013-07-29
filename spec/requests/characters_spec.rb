require 'spec_helper'
include Helpers

describe "Characters" do
  describe "Add character" do
    it "adds a character and allows another to be added" do
      
      visit new_character_path
      fill_in "Simplified", :with => "人"
      click_button "Create Character"
      
      page.should have_content("successfully")
      
      page.should have_content("Simplified")
    end
  end
end
