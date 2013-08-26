namespace :export do 
  desc "Export radicals, characters and words for use in Core Data"
  task :obj_c => :environment do 
    File.open("/Users/sjors/Dropbox/Kangxi/iOs/Kangxi Radicals/Kangxi Radicals/import.h", 'w') do |f| 
      f << "#import <UIKit/UIKit.h>\n"
      f << "#import \"Radical.h\"\n"
      f << "#import \"Character.h\"\n"
      f << "#import \"Word.h\"\n"
      f << "\n"
      f << "@interface Populator : NSObject\n"
      f << "+(void)import:(NSManagedObjectContext *)managedObjectContext;\n"
      f << "@end\n"
    end
    
    
    File.open("/Users/sjors/Dropbox/Kangxi/iOs/Kangxi Radicals/Kangxi Radicals/import.m", 'w') do |f| 
      f << "#import \"import.h\"\n"
      f << "@implementation Populator\n"

      f << "+(void)import:(NSManagedObjectContext *)managedObjectContext {\n"
      f << "  NSError *error;\n"
      f << "  Radical* r;\n"
      f << "  Radical* r2;\n"
      f << "  int cTally;\n"
    
      puts "Screen 1..."
      f << "//*********** \n"
      f << "// Screen 1 * \n" 
      f << "//*********** \n"
      f << "NSLog(@\"Screen 1\");\n"
      Radical.export_screen_1_and_2_radicals(1,f)
      
      puts "Screen 2..."
      f << "//*********** \n"
      f << "// Screen 2 * \n" 
      f << "//*********** \n"
      f << "NSLog(@\"Screen 2\");\n"
      Radical.export_screen_1_and_2_radicals(2,f)
      
      puts "Screen 3..."
      f << "//*********** \n"
      f << "// Screen 3 * \n" 
      f << "//*********** \n"
      f << "NSLog(@\"Screen 3\");\n"
      Radical.export_screen_3_radicals(f)
      
      puts "Screen 4..."
      f << "//*********** \n"
      f << "// Screen 4 * \n" 
      f << "//*********** \n"
      f << "NSLog(@\"Screen 4\");\n"
      Radical.export_screen_4_radicals(f)
      
      f << "}\n"
      f << "@end\n"
    end
  end
end