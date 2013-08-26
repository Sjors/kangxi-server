namespace :export do 
  desc "Export radicals, characters and words for use in Core Data"
  task :obj_c => :environment do 
    File.open("/Users/sjors/Dropbox/Kangxi/iOs/Kangxi Radicals/Kangxi Radicals/import.h", 'w') do |f| 
      f << "#import <UIKit/UIKit.h>\n"
      f << "#import \"Radical.h\"\n"
      f << "\n"
      f << "@interface Populator : NSObject\n"
      f << "+(void)import:(NSManagedObjectContext *)managedObjectContext;\n"
      f << "@end\n"
    end
    
    
    File.open("/Users/sjors/Dropbox/Kangxi/iOs/Kangxi Radicals/Kangxi Radicals/import.m", 'w') do |f| 
      f << "#import \"import.h\"\n"
      f << "@implementation Populator\n"

      f << "+(void)import:(NSManagedObjectContext *)managedObjectContext {\n"
      f << "  int sectionTally = 0;\n"
      f << "  for(NSArray *section in @[\n"
      f << "    @[" + Radical.where(first_screen: true).collect{|r| "@\"#{ r.simplified }\"" }.join(", ") + "],\n"
      f << "    @[" + Radical.where(second_screen: true).collect{|r| "@\"#{ r.simplified }\"" }.join(", ") + "],\n"
      f << "    @[" + Radical.where(third_screen: true).collect{|r| "@\"#{ r.simplified }\"" }.join(", ") + "]\n"
      f << "    ]) {\n"
      f << "    int tally = 0;\n"
      f << "    for(NSString *radical in section ) {\n"
      f << "      Radical* r = [NSEntityDescription insertNewObjectForEntityForName:kEntityRadical\n"  
      f << "                                        inManagedObjectContext:managedObjectContext];\n"
      f << "      r.isFirstRadical = [NSNumber numberWithBool:(sectionTally == 0 || sectionTally == 1)];\n"
      f << "      r.simplified = radical;\n"
      f << "      r.position = [NSNumber numberWithInt:tally];\n"
      f << "      r.section = [NSNumber numberWithInt:sectionTally];\n"
      f << "      tally++;\n"
      f << "    }\n"
      f << "    sectionTally++;\n"
      f << "  }\n"
      f << "}\n"
      f << "@end\n"
    end
  end
end