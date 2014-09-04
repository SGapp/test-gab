require 'rubygems'
require 'bundler/setup'
require 'pry'
require 'pdf-reader'

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
    content.scan(/ARTICLE.*?(?=ARTICLE|\.\n*\s*TITRE|\z)/m).map do |article|
      Article.new(article)
    end
  end

  private

  def doc_pages(reader)
    reader.pages.map(&:text).map do |page|
      page.gsub(/\s+\d+\z/, '')
    end
  end
end

class Article
  attr_reader :full_article, :sub_articles

  def initialize(full_article)
    @full_article = full_article.strip.squeeze(" \n\t\r")
    @sub_articles = sub_articles
  end

  def title
    @title ||= full_article[/ARTICLE\s*[\d]*\s*[-•\.]*[^\n\r\t]+/]
  end

  def sub_articles
    unless @sub_articles
      @sub_articles = []
      number = full_article[/(ARTICLE\s*)([\d]*)\s*[-•\.]*/, 2]
      full_article.scan(/^#{number}.*?(?=#{number}|#{number.to_i+1}|\z)/im).each do |sub_article|
        @sub_articles << SubArticle.new(sub_article)
      end
    end

    @sub_articles
  end


  def content
    @content ||= full_article[/#{Regexp.escape title}(.*)/m, 1]
  end

  def self.all
    ObjectSpace.each_object(self).to_a.reverse
  end
end

class SubArticle
  attr_reader :sub_article

  def initialize(sub_article)
    @sub_article = sub_article
  end

  def content
    @sub_article
  end

end

doc = Document.new('statuts_sas_ercisol.pdf')

articles = doc.articles

approval = ""
articles.each do |article|
  approval = article.full_article if article.title =~ /agrément/i || article.content =~ /demande d'agrément/i
  if article.sub_articles.count > 0
    article.sub_articles.each do |sub_article|
      approval = sub_article.content if sub_article.content =~ /agrément/i && sub_article.content =~ /demande d'agrément/
    end
  end
end

puts approval

    # corporate_bodies = []
    # articles.each do |article|
    #   if article.title =~ /comité/i
    #     corporate_bodies << article.title
    #     break
    #   end
    #   if article.title =~ /commission/i
    #     corporate_bodies << article.title
    #     break
    #   end
    #   if article.title =~ /direction/i
    #     corporate_bodies << article.title
    #     break
    #   end
    # end
    # if corporate_bodies == []
    #   puts "Les statuts ne comportent d'autres organes sociaux."
    # else
    #   puts corporate_bodies.join(" ,")
    # end







