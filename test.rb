require 'rubygems'
require 'bundler/setup'

require 'pdf-reader'

# filename = 'statuts_dariobat'
# docs = Dir[filename+'.pdf']
# puts Docsplit.extract_text(docs, :ocr => true, :output => 'storage/text')
# text = File.read('storage/text/'+ filename + '.txt')
# puts text

# reader = PDF::Reader.new('statuts_sas_ercisol.pdf')

# puts reader.page_count

# pages = reader.pages.map do |page|
#    page.text
# end

# pages = pages.each do |page|
#   last_two = page.split(//).last(2).join('')
#   page.gsub!(/#{last_two}/, '') if last_two =~ /^[ |\d]+$/
# end

# content = pages.join("\n")

# content = content.gsub!(/[\n]+/, "\n")

# File.open("out2.txt", 'w') {|f| f.write("#{content}") }

# content = content.gsub!(/(?<=[^\.:!?-])([\n]+)(?=([^A-Z\d]))/m, " ")

# content = content.gsub!(/(?<![ARTICLE ])\d+/m, "\n")

# File.open("out3.txt", 'w') {|f| f.write("#{content}") }

class Document
  attr_reader :reader, :content

  def initialize(text_path)
    @reader = PDF::Reader.new(text_path)
  end

  def content
    @content ||= doc_pages(reader).join("\n")
                                  .gsub(/[\n]+/, "\n")
                                  .gsub(/(?<=[^\.:!?-])([\n]+)(?=([^A-Z\d]))/m, " ")
  end

  def articles
    content.scan(/^ARTICLE.*?(?=ARTICLE|TITRE|\z)/m)
  end

  private

  def doc_pages(reader)
    reader.pages.map(&:text).map do |page|
      page.gsub(/\s+\d+\z/, '')
    end
  end
end

class Article
  attr_reader :full_article

  def initialize(full_article)
    @full_article = full_article.strip.squeeze(" \n\t\r")
  end

  def title
    @title ||= full_article[/ARTICLE\s*[\d]*\s*[\.|-]*[^\n]+/]
  end

  def content
    @content ||= full_article[/#{Regexp.escape title}(.*)/m, 1]
  end

  def self.all
    ObjectSpace.each_object(self).to_a.reverse
  end
end

# articles_number = content.scan(/ARTICLE\s+[\d]+/)

doc = Document.new('statuts_sas_ercisol.pdf')

# doc.articles.each do |article|
#   print article
#   puts '*'*50
# end

# article_title = content.scan(/ARTICLE\s*[\d]+[\.|-]*[^\n]+/)


# articles_content = content.scan(/(^ARTICLE.*?(?=ARTICLE|TITRE|\z))/m)

doc.articles.map do |article|
  Article.new(article)
end

articles_hash = {}
Article.all.each do |article|
  articles_hash[article.title] = article.content
end

company_name = doc.content[/(^.*?(?=société|Société))/m].strip.gsub(/\s{2}+/, "")
company_form = doc.content[/(SAS|SARL|SA|SCI|EURL|SASU|S\.A\.S|S\.A\.R\.L|S\.A|S\.C\.I|E\.U\.R\.L|S\.A\.S\.U)/]

company_name_article = []
Article.all.each do |article|
  company_name_article << article.full_article if article.full_article[/(dénomination sociale|DENOMINATION)/]
end

company_head_office = []
Article.all.each do |article|
  company_head_office << article.full_article if article.full_article[/siège social est/]
end


company_share_capital = []
Article.all.each do |article|
  company_share_capital << article.full_article if article.full_article[/(capital social|capital initial)/] && article.full_article[/libéré/] && !article.full_article[/apport/]
end

company_purpose = []
Article.all.each do |article|
  company_purpose << article.full_article if article.full_article =~ /objet social est/ || article.full_article =~ /a pour objet/
end

company_directors = []
Article.all.each do |article|
  if article.title =~ /président directeur général/i
    company_directors << "Président Directeur Général"
  elsif article.title =~ /président/i
    company_directors << "Président"
  elsif article.title =~ /gérant/i
    company_directors << "Gérant"
  elsif article.title =~ /directoire/i
    company_directors << "Directoire"
  end
  company_directors << "Directeur Général Délégué" if article.title =~ /directeur général délégué/i
  company_directors << "Directeur Général" if article.title =~ /directeur général/i
end

# powers_article = []

# company_directors.each do |director|
#   articles_content.flatten.each do |article|
#     powers_article << article if article =~ /(#{director} ne peut|#{director} ne pourra|#{director} ne pourront|autorisation préalable|sans l'accord)/i
#   end
# end

power_chunk = {}
company_directors.each do |director|
  Article.all.each do |article|
  if article.content =~ /(?<=\.)([^\.]*(?:#{director} ne peut|#{director} ne pourra|#{director} ne pourront|autorisation préalable|sans l'accord)[^\.]*)(?=\.)/i
    power_chunk[article.title] = article.content[/(?<=\.)([^\.]*(?:#{director} ne peut|#{director} ne pourra|#{director} ne pourront|autorisation préalable|sans l'accord)[^\.]*)(?=\.)/i]
  end
  end
end

company_corporate_bodies = []
Article.all.each do |article|
  if article.title =~ /comité/i
    company_corporate_bodies << article.title[/(ARTICLE\s+[\d]+.)(.+)/, 2]
    break
  end
  if article.title =~ /commission/i
    company_corporate_bodies << article.title[/(ARTICLE\s+[\d]+.)(.+)/, 2]
    break
  end
  if article.title =~ /direction/i
    company_corporate_bodies << article.title[/(ARTICLE\s+[\d]+.)(.+)/, 2]
    break
  end
end

company_lenght = []

Article.all.each do |article|
  company_lenght << article.full_article if article.full_article =~ /(durée|duree)/i && article.full_article =~ /(est fixée)/i && article.full_article =~ /(immatriculation)/i
end

company_social_decisions = []

Article.all.each do |article|
  company_social_decisions << article.full_article if article.title =~ /(assemblée générale|décisions collectives|décisions des associés|décisions d'associés)/i
end

print company_social_decisions














# puts File.read("out.txt").match(/^ARTICLEGKJBKJBV/)
