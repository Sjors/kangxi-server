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

  
  describe "radical" do
    let(:admin) { FactoryGirl.create(:admin) }
    let(:character) { FactoryGirl.create(:character, :simplified => "爱") }
    let(:radical) { FactoryGirl.create(:radical, :simplified => "夂", :position => 34) }
    
    
    before do
      FactoryGirl.create(:radical, :simplified => "一", :position => 1)
      character.radicals << radical
      login(admin)
    end
    
    it "list is shown on the character page" do
      visit character_path(character)
      within "ul.radicals" do
        page.should have_content(radical.simplified)
      end
    end
    
    it "can be added" do
      visit character_path(character)
      within "ul.radicals" do
        page.should_not have_content('一')
      end
      select('一', :from => 'radical')
      click_button "Add Radical"
      within "ul.radicals" do
        page.should have_content('一')
      end
    end
    
    it "can be selected by tapping on a radical in the list", :js => true do
      visit character_path(character)
      select('夂', :from => 'radical')
      
      find_field("radical").value.to_i.should eq(Radical.where(position: 34).first.id)
      # When :js => false, use this:
      # find_field('radical').find('option[selected]').text.should eq("夂")
      within ".form-inputs" do
        click_link "一"
      end
      find_field("radical").value.to_i.should eq(Radical.where(position: 1).first.id)
      
    end
    
    it "can be removed" do
      visit character_path(character)
      within "ul.radicals" do
        page.should have_content('夂')
        click_link ""
      end
      within "ul.radicals" do
        page.should_not have_content('夂')
      end
    end
  end
end
