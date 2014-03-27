namespace :export do 
  desc "Export radicals, characters and words for use in Core Data"
  task :obj_c => :environment do 
    File.open("/Users/sjors/Dropbox/Kangxi/iOs/KangxiRadicals/Kangxi Radicals/import.h", 'w') do |f| 
      f << "#import <UIKit/UIKit.h>\n"
      f << "#import \"Radical.h\"\n"
      f << "#import \"Character.h\"\n"
      f << "#import \"Word.h\"\n"
      f << "\n"
      f << "@interface Populator : NSObject\n"
      f << "+(void)import:(NSManagedObjectContext *)managedObjectContext;\n"
      f << "+(void)synonyms:(NSManagedObjectContext *)managedObjectContext;\n"
      f << "@end\n"
    end
    
    
    File.open("/Users/sjors/Dropbox/Kangxi/iOs/KangxiRadicals/Kangxi Radicals/import.m", 'w') do |f| 
      f << "#import \"import.h\"\n"
      f << "@implementation Populator\n"

      f << "+(void)import:(NSManagedObjectContext *)managedObjectContext {\n"
      f << "  NSError *error;\n"
      f << "  Radical* r;\n"
      f << "  Radical* r2;\n"
    
      Radical.export_radicals(f)
      
      f << "}\n"
      
      puts "Synonyms..."
      f << "//*********** \n"
      f << "// Synonyms * \n" 
      f << "//*********** \n"
      
      Radical.export_synonyms(f)
      
      f << "@end\n"
    end
  end
end