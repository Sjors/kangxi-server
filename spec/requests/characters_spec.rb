require 'spec_helper'
include Helpers

describe "Character" do
  let(:admin) { FactoryGirl.create(:admin) }
  
  describe "list" do
    it "is the first thing an anymous user sees" do
      FactoryGirl.create(:character, :simplified => "人")
      login(admin)
    
      visit "/"
      click_link "Characters"
      page.should have_content "人"
    end
    
    it "can be added sequentially" do
      login(admin)
      
      
      visit new_character_path
      fill_in "Simplified", :with => "人"
      click_button "Create Character"
      
      page.should have_content("Successfully")
      
      page.should have_content("Simplified")
    end
  end

  
  describe "radicals" do
    let(:admin) { FactoryGirl.create(:admin) }
    let(:character) { FactoryGirl.create(:character, :simplified => "爱") }
    let(:radical) { FactoryGirl.create(:radical, :simplified => "夂") }
    
    before do
      character.radicals << radical
      login(admin)
    end
    
    it "are shown on the character page" do
      visit character_path(character)
      page.should have_content(radical.simplified)
    end
    
    it "can be added" do
    end
    
    # it "can be removed" do
    # end
  end
end
