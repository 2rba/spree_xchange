# encoding: UTF-8

=begin
spree_core/lib/spree/core/permalinks.rb
-          other = self.class.all(:conditions => "#{field} LIKE '#{permalink_value}%'")
   	 50 	
+          other = self.class.all(:conditions => ["#{field} LIKE ?", "#{permalink_value}%"])

Installation steps
rails _3.2.6_ new spree6 -d mysql
cd spree6
create database, and edit config/database.yml
spree install --version=1.1.2
failure
bundle update
spree install --version=1.1.2
add to Gemfile
gem 'rails-i18n'
gem 'spree_i18n', :git => 'https://github.com/2rba/spree_i18n'
gem 'spree_xchange', :path => '../spree_xchange'
gem 'spree_simpleco', :path => '../spree_simpleco'
bundle

edit config/application.rb
     config.i18n.default_locale = :uk
rake spree_xchange:install:migrations
rake db:migrate





=end
require 'digest/md5'
require "nokogiri"


class Exchange1cController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :authenticate

  def test

    render :xml => builder.to_xml
=begin
    xchangeId='60b438f8-3e9e-11dc-8e55-0019d171d567'.gsub('-','')
    name = 'test'
    p = Spree::Product.where('xchange_id = UNHEX(?)', xchangeId).first_or_create
    p.name = name
    p.price=0
    p.xchange_id = Array(xchangeId).pack('H*')
    p.save!
    render :text => p.inspect.to_s.html_safe
=end
  end

  def main
    case params[:mode]
      when 'checkauth'
        #session[:time]=Time.now.to_i
        time = Time.now.to_i.to_s
        Dir.mkdir('/tmp/' + Digest::MD5.hexdigest(@user.email) + '_'  + time)
        #session[:id]=1 if session[:id].nil?
        #session[:id]=session[:id]+1
    render :text => "success\nsession_id\n" + time + "\n"
      when 'init'
        render :text => "zip=no\nfile_limit=1024000"
      when 'query'
        builder = Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |xml|
          xml.КоммерческаяИнформация(ВерсияСхемы: '2.03') {
              Spree::Order.where(id: 1069267030).all.each do |order|
                xml.Документ {
                  xml.Ид order.id
                  xml.Номер order.id
                  xml.Дата order.created_at.strftime('%Y-%m-%d')
                  xml.ХозОперация 'Заказ товара'
                  xml.Роль 'Продавец'
                  xml.Валюта 'грн'
                  xml.Курс '1'
                  xml.Сумма order.item_total
                  xml.Контрагенты {
                    xml.Контрагент {
                      xml.Ид order.user_id
                      xml.Наименование order.email
                      xml.Роль 'Покупатель'
                      xml.ПолноеНаименование order.email
                      xml.Фамилия order.bill_address.lastname
                      xml.Имя order.bill_address.firstname
                    }
                  }
                  xml.Время order.created_at.strftime('%H:%M:%S')
                  xml.Комментарий order.special_instructions
                  xml.Товары{
                    order.line_items.each{
                      |item|
                      xml.Товар{
                        xml.Ид strAddDash item.variant.product.xchange_id.unpack('H*').first.to_s
                        xml.Наименование item.variant.product.name
                        xml.ЦенаЗаЕдиницу item.price
                        xml.Количество  item.quantity
                        xml.Сумма item.price*item.quantity
                      }
                    }
                  }
                }
              end
          }
        end
        render :xml => "\xEF\xBB\xBF"+builder.to_xml #'<?xml version="1.0" encoding="UTF-8"?><КоммерческаяИнформация ВерсияСхемы="2.03" ДатаФормирования="2007-10-30">'+"\n"+'</КоммерческаяИнформация>'
      when 'success'
        render :text => 'ok'
      when 'file'
        # filename
        # type=catalog
        case params[:filename]
          when 'import.xml'
            filename = 'import.xml'
          when 'offers.xml'
            filename = 'offers.xml'
          else
            filename = Digest::MD5.hexdigest(params[:filename])
        end


        filename = '/tmp/' + Digest::MD5.hexdigest(@user.email) + '_' + cookies[:session_id].to_s  + '/' + filename
        File.open(filename,'a') {|f| request.body.set_encoding("UTF-8"); f.write(request.body.string)}
        render :text=>'success'
      when 'import'
        case params[:filename]
          when 'import.xml'
            filename = 'import.xml'
            filename = '/tmp/' + Digest::MD5.hexdigest(@user.email) + '_' + cookies[:session_id].to_s + '/' + filename
            xml = Nokogiri::XML(File.open(filename))
            # catalog import
            tmy = Spree::Taxonomy.where('name = ?', 'Каталог').first
            if tmy.nil?
              tmy = Spree::Taxonomy.create(:name => 'Каталог')
              taxon = tmy.root
              taxon.permalink = 'catalog'
              taxon.save
            end
            rootGroup = tmy.taxons.where(:parent_id => nil).first

            xml.xpath("КоммерческаяИнформация/Классификатор/Группы").each{
              |groups|
              groups.xpath("Группа").each{
                |groupNode|

                processGroup(groupNode, rootGroup, tmy)
              }

            }

            # products import
            r = xml.xpath("//Товар")
            r.each{
              |nodeProduct|
              id = nodeProduct.xpath("Ид").first.content.gsub('-','')
              if ((i = id.index('#')).nil?)
                xchangeId = id
              else
                xchangeId = id[0..(i-1)]
                variantId = id[(i+1)..-1]
              end
              product = Spree::Product.where('xchange_id = UNHEX(?)', xchangeId).first_or_create
              product.name = nodeProduct.xpath("Наименование").first.content
              description =  nodeProduct.xpath("Описание").first
              product.description = (description.nil?) ? '' : description.content
              product.xchange_id = Array(xchangeId).pack('H*')
              product.price=0 if product.price.nil?

              groupId = nodeProduct.xpath("Группы/Ид").first.content.gsub('-','')
              group = Spree::Taxon.where('xchange_id = UNHEX(?)', groupId).first
              product.taxons << group unless product.taxons.exists?(group)

              product.save

              if (i)
                variant = product.variants.where('xchange_id = UNHEX(?)', variantId).first
                if variant.nil?
                  variant = product.variants.create
                  variant.xchange_id = Array(variantId).pack('H*')
                  variant.price=0
                  variant.save
                end
                  nodeProduct.xpath("ХарактеристикиТовара/ХарактеристикаТовара").each do |xoption|
                    name = xoption.xpath('Наименование').first.content
                    optionName = "xchange-#{name}".to_param
                    optionType = Spree::OptionType.where( :name => optionName ).first
                    if optionType.nil?
                      optionType = Spree::OptionType.new(:name => optionName, :presentation => name)
                      optionType.save
                    end

                    optionValueStr = xoption.xpath('Значение').first.content
                    optionValue = Spree::OptionValue.where( :option_type_id => optionType, :name => optionValueStr).first
                    if optionValue.nil?
                      optionValue = optionType.option_values.create(:name => optionValueStr, :presentation =>optionValueStr)
                      #optionValue = Spree::OptionValue.new( :option_type_id => optionType, :name => optionValueStr)
                      #optionValue
                    end

                if not variant.option_values.exists?(optionValue)
                  variant.option_values << optionValue
                  variant.save
                end

                end
              end



              #p v
              #hash = {}
              #p.children.each do |node|
              #    hash[node.node_name] = node.content
              #  end
              #p hash
            }
          when 'offers.xml'
            filename = 'offers.xml'
            filename = '/tmp/' + Digest::MD5.hexdigest(@user.email) + '_' + cookies[:session_id].to_s + '/' + filename
            xml = Nokogiri::XML(File.open(filename))
            r = xml.xpath("//Предложение")
            r.each{
              |nodeOffer|
              id = nodeOffer.xpath("Ид").first.content.gsub('-','')
              if ((i = id.index('#')).nil?)
                xchangeId = id
                product = Spree::Product.where('xchange_id = UNHEX(?)', xchangeId).first
                variant = product
              else
                xchangeId = id[0..(i-1)]
                variantId = id[(i+1)..-1]
                product = Spree::Product.where('xchange_id = UNHEX(?)', xchangeId).first
                variant = product.variants.where('xchange_id = UNHEX(?)', variantId).first
              end
              variant.price = nodeOffer.xpath('Цены/Цена/ЦенаЗаЕдиницу').first.content.to_i
              variant.count_on_hand = nodeOffer.xpath('Количество').first.content.to_i
              product.available_on = Time.now
              #if variant.count_on_hand > 0
              #  product.available_on = Time.now
              #else
              #  product.available_on =nill
              #end
              product.save
              variant.save
              #p v
              #hash = {}
              #p.children.each do |node|
              #    hash[node.node_name] = node.content
              #  end
              #p hash
            }

          else
            filename = '/tmp/' + Digest::MD5.hexdigest(@user.email) + '_' + cookies[:session_id].to_s + '/' + Digest::MD5.hexdigest(params[:filename])
        end
        render :text => 'success'
    end
  end
  private
  def strAddDash(str)
    str.scan(/^(.{8})(.{4})(.{4})(.{4})(.{12})$/).join('-')
  end


  def processGroup(groupNode, parentGroup, tmy)
    xchangeId = groupNode.xpath("Ид").first.content.gsub('-','')
    group = Spree::Taxon.where('xchange_id = UNHEX(?)', xchangeId).first_or_create
    group.xchange_id = Array(xchangeId).pack('H*')
    group.parent_id=parentGroup.id
    group.name=groupNode.xpath("Наименование").first.content
    group.taxonomy_id=tmy.id
    group.save
    groupNode.xpath("Группы/Группа").each{
      |groupNode2|
      processGroup(groupNode2, group, tmy)
    }
  end

def authenticate
  authenticate_or_request_with_http_basic do |username, password|
    @user = Spree::User.find_by_email(username)
    @user && @user.has_role?("admin") && password == @user.api_key

#    username == "foo" && password == "bar"
  end
end

end