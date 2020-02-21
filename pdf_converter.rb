# frozen_string_literal: true

# Uses https://github.com/lshepstone/gs-ruby for the Ghostscript command
require 'sinatra'
require 'gs-ruby'
require 'pry'

set :root, File.dirname(__FILE__)
set :server_settings, timeout: 120

# PDF Converter
class PdfConverter < Sinatra::Base
  get '/' do
    erb :form
  end

  post '/process_pdf' do
    unless params[:file] && params[:file][:tempfile] && params[:file][:filename]
      return erb :form
    end

    @filename = params[:file][:filename].gsub!(/[^0-9A-Za-z.]/, '')
    @output_file_name = "#{Time.now.strftime('%b_%d_%I_%M')}_#{@filename}"
    @file = params[:file][:tempfile]

    File.open("#{settings.root}/tmp/#{@filename}", 'wb') do |file|
      file.write(@file.read)
      file.close
    end

    @pdf = GS.run("#{settings.root}/tmp/#{@filename}") do |command|
      command.option(GS::PDFA)
      command.option(GS::BATCH)
      command.option(GS::NO_PAUSE)
      command.option(GS::PROCESS_COLOR_MODEL, 'DeviceCMYK')
      command.option(GS::DEVICE, 'pdfwrite')
      command.option(GS::PDFA_COMPATIBILITY_POLICY, '1')
      command.option('CompatibilityLevel', '1.4')
      command.option('PDFSETTINGS', 'prepress')
      command.option(GS::OUTPUT_FILE,
                     "#{settings.root}/tmp/#{@output_file_name}")
    end

    stream do |out|
      until @pdf.success?
        out << '\0'
        sleep 1
      end
    end

    erb :process_pdf
  end
end
