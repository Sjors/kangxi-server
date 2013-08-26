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
      f << "  NSError *error;\n"
      f << "  Radical* r;\n"
      f << "  Radical* r2;\n"
      
      @radicals = Radical.where(first_screen: true).to_a
      @radicals.each_index do |i|
        f << "  r = [NSEntityDescription insertNewObjectForEntityForName:kEntityRadical\n"  
        f << "               inManagedObjectContext:managedObjectContext];\n"
        f << "  r.isFirstRadical = @YES;\n"
        f << "  r.simplified = @\"#{ @radicals[i].simplified }\";\n"
        f << "  r.position = [NSNumber numberWithInt:#{ i }];\n"
        f << "  r.section = @0;\n"  
        f << "\n"
        @second_radicals = Radical.where("id in (?)", @radicals[i].radicals).to_a
        @second_radicals.each_index do |j|
          f << "  r2 = [NSEntityDescription insertNewObjectForEntityForName:kEntityRadical\n"  
          f << "               inManagedObjectContext:managedObjectContext];\n"
          f << "  r2.isFirstRadical = @NO;\n"
          f << "  r2.firstRadical = r;\n"
          f << "  r2.simplified = @\"#{ @second_radicals[j].simplified }\";\n"
          f << "  r2.position = [NSNumber numberWithInt:#{ j }];\n"
          f << "  r2.section = @0;\n"  
          f << "\n"
        end
        f << "\n"
        f << "  error = nil;\n"
        f << "  [managedObjectContext save:&error];\n"
        f << "  if(error != nil) { NSLog(@\"%@\", error); }"
        f << "\n\n"
      end
      
      
      # f << "  int sectionTally = 0;\n"
      # f << "  for(NSArray *section in @[\n"
      # f << "    @[" + Radical.where(first_screen: true).collect{|r| "@\"#{ r.simplified }\"" }.join(", ") + "],\n"
      # f << "    @[" + Radical.where(second_screen: true).collect{|r| "@\"#{ r.simplified }\"" }.join(", ") + "],\n"
      # f << "    @[" + Radical.where(third_screen: true).collect{|r| "@\"#{ r.simplified }\"" }.join(", ") + "]\n"
      # f << "    ]) {\n"
      # f << "    int tally = 0;\n"
      # f << "    for(NSString *radical in section ) {\n"
      # f << "      Radical* r = [NSEntityDescription insertNewObjectForEntityForName:kEntityRadical\n"  
      # f << "                                        inManagedObjectContext:managedObjectContext];\n"
      # f << "      r.isFirstRadical = [NSNumber numberWithBool:(sectionTally == 0 || sectionTally == 1)];\n"
      # f << "      r.simplified = radical;\n"
      # f << "      r.position = [NSNumber numberWithInt:tally];\n"
      # f << "      r.section = [NSNumber numberWithInt:sectionTally];\n"
      # f << "      tally++;\n"
      # f << "    }\n"
      # f << "    sectionTally++;\n"
      # f << "  }\n"
      f << "}\n"
      f << "@end\n"
    end
  end
end