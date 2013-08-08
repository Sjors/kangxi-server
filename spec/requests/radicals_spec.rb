require 'spec_helper'
include Helpers

describe "Radicals" do
  let(:admin) { FactoryGirl.create(:admin) }
  
  it "anonymous user can see the list of radicals" do
    FactoryGirl.create(:radical, :simplified => "人")
    visit radicals_path
    page.should have_content "人"
  end
  
  describe "Add radical" do
    it "admin can add a radical" do
      login(admin)
      visit new_radical_path
      fill_in "Simplified", :with => "人"
      fill_in "Position", :with => "9"
      click_button "Create Radical"
          
      page.should have_content("人")
    end
  end
end
