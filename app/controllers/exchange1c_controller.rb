# encoding: UTF-8
require 'digest/md5'
require "nokogiri"

class Exchange1cController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def test
    xchangeId='60b438f8-3e9e-11dc-8e55-0019d171d567'.gsub('-','')
    name = 'test'
    p = Spree::Product.where('xchange_id = UNHEX(?)', xchangeId).first_or_create
    p.name = name
    p.price=0
    p.xchange_id = Array(xchangeId).pack('H*')
    p.save!
    render :text => p.inspect.to_s.html_safe
  end

  def main
    username='myuser'
    case params[:mode]
      when 'checkauth'
        #session[:time]=Time.now.to_i
        time = Time.now.to_i.to_s
        Dir.mkdir('/tmp/'+time)
        #session[:id]=1 if session[:id].nil?
        #session[:id]=session[:id]+1
    render :text => "success\nsession_id\n" + time + "\n"
      when 'init'
        render :text => "zip=no\nfile_limit=1024000"
      when 'query'
        render :text => "\xEF\xBB\xBF"+'<?xml version="1.0" encoding="UTF-8"?><КоммерческаяИнформация ВерсияСхемы="2.03" ДатаФормирования="2007-10-30">'+"\n"+'</КоммерческаяИнформация>'
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
            filename = Digest::MD5.hexdigest(username + params[:filename])
        end


        filename = '/tmp/' + cookies[:session_id].to_s + '/' + filename
        File.open(filename,'a') {|f| request.body.set_encoding("UTF-8"); f.write(request.body.string)}
        render :text=>'success'
      when 'import'
        case params[:filename]
          when 'import.xml'
            filename = 'import.xml'
          when 'offers.xml'
            filename = 'offers.xml'
          else
            filename = Digest::MD5.hexdigest(username + params[:filename])
        end
        filename = '/tmp/' + cookies[:session_id].to_s + '/' + filename
        xml = Nokogiri::XML(File.open(filename))
        r = xml.xpath("//Товар")
        r.each{
          |p|
          hash = {}
          p.children.each do |node|
              hash[node.node_name] = node.content
            end
          p hash
        }
        render :text => 'success'
    end
  end
end