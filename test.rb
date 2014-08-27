require 'rubygems'
require 'bundler/setup'

require 'pdf-reader'

# filename = 'statuts_dariobat'
# docs = Dir[filename+'.pdf']
# puts Docsplit.extract_text(docs, :ocr => true, :output => 'storage/text')
# text = File.read('storage/text/'+ filename + '.txt')
# puts text

reader = PDF::Reader.new('statuts_sas_ercisol.pdf')

# puts reader.page_count

pages = reader.pages.map do |page|
   page.text
end

pages = pages.each do |page|
  last_two = page.split(//).last(2).join('')
  page.gsub!(/#{last_two}/, '') if last_two =~ /^[ |\d]+$/
end

content = pages.join("\n")

content = content.gsub!(/[\n]+/, "\n")

File.open("out2.txt", 'w') {|f| f.write("#{content}") }

content = content.gsub!(/(?<=[^\.:!?-])([\n]+)(?=([^A-Z\d]))/m, " ")

# content = content.gsub!(/(?<![ARTICLE ])\d+/m, "\n")

File.open("out3.txt", 'w') {|f| f.write("#{content}") }

articles_number = content.scan(/ARTICLE\s+[\d]+/)

article_title = content.scan(/ARTICLE\s[\d]+\.+[^\n]+/)

puts article_title

articles_content = content.scan(/(^ARTICLE.*?(?=ARTICLE|TITRE|\z))/m)

company_name = content[/(^.*?(?=société|Société))/m].strip.gsub(/\s{2}+/, "")

company_name_article = []
articles_content.flatten.each do |article|
  company_name_article << article if article.include?("dénomination sociale") || article.include?("DENOMINATION")
end

company_head_office = []
articles_content.flatten.each do |article|
  company_head_office << article if article.include?("siège social est")
end

company_share_capital = []
articles_content.flatten.each do |article|
  company_share_capital << article if article[/(capital social|capital initial)/] && article[/libéré/] && !article[/apport/]
end


company_form = content[/(SAS|SARL|SA|SCI|EURL|SASU|S\.A\.S|S\.A\.R\.L|S\.A|S\.C\.I|E\.U\.R\.L|S\.A\.S\.U)/]

company_purpose = []
articles_content.flatten.each do |article|
  company_purpose << article if article =~ /objet social est/ || article =~ /a pour objet/
end

company_directors = []
article_title.flatten.each do |title|
  if title =~ /président directeur général/i
    company_directors << "Président Directeur Général"
  elsif title =~ /président/i
    company_directors << "Président"
  elsif title =~ /gérant/i
    company_directors << "Gérant"
  elsif title =~ /directoire/i
    company_directors << "Directoire"
  end
  company_directors << "Directeur Général Délégué" if title =~ /directeur général délégué/i
  company_directors << "Directeur Général" if title =~ /directeur général/i
end

powers_article = []

company_directors.each do |director|
  articles_content.flatten.each do |article|
    powers_article << article if article =~ /(#{director} ne peut|#{director} ne pourra|#{director} ne pourront|autorisation préalable|sans l'accord)/i
  end
end

power_chunk = []
company_directors.each do |director|
  powers_article.flatten.each do |article|
    power_chunk << article.scan(/(?<=\.)([^\.]*(?:#{director} ne peut|#{director} ne pourra|#{director} ne pourront|autorisation préalable|sans l'accord)[^\.]*)(?=\.)/i)
  end
end

company_corporate_bodies = []
article_title.flatten.each do |title|
  if title =~ /(comité|commission|direction)/i
    company_corporate_bodies << title[/(ARTICLE\s+[\d]+.)(.+)/, 2]
  end
end

puts company_corporate_bodies












# puts File.read("out.txt").match(/^ARTICLEGKJBKJBV/)
