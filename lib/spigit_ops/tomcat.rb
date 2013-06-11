require 'nokogiri'

module SpigitOps
  class Tomcat
    def initialize(serverxml_filename = "/opt/tomcat/conf/server.xml", options= {})
      attr_reader :serverxml_filename

      if ! FileTest.exist? @serverxml_filename
  			$stderr.puts "#{@serverxml_filename} doesn't exist, exiting..."
  			exit
			elsif ! FileTest.readable? @serverxml_filename
  			$stderr.puts "#{@serverxml_filename} isn't readable, exiting..."
  			exit
	  	end

	  	@serverxml_filename = serverxml_filename
	  	@serverxml_xml = Nokogiri::XML(File.open(@serverxml_filename))
	  end

	  def services
	  	puts @tomcat_services
	  end

	  private

    	def build_services
        @services = {}
    		@serverxml_xml.xpath('//Service').each do |service|
    		  name = service[:name]
    		  start_line = service.line
    		  end_line   = end_line_lookup[start_line]

    		  # Create an array with all connectors and the needed attributes in a hash
    		  connectors = []
    		  service.children.css('Connector').each do |connector|
    		    connectors << {:ip => connector[:address], :port => connector[:port]}
    		  end

    		  # Create an array with all docBases
    		  docBase = []
    		  service.children.css('Context').each do |context|
    		    docBase << context[:docBase]
    		  end

    		  resources = []
    		  service.children.css('Resource').each do |resource|
    		    db_host     = resource[:url].scan(%r{mysql://(.*)/}).join.sub(/^127\.0\.0\.1$/, "localhost")
    		    schema_name = resource[:url].scan(%r{/([^/]+)\?}).join

    		    if resources.empty?
    		      resources << {:db_host => db_host, :schema_name => schema_name}
    		    else
    		      duplicate=""
    		      resources.each do |i|
    		        if i[:db_host] == db_host and i[:schema_name] == schema_name
    		          duplicate=true
    		        end
    		      end
    		      if duplicate != true
    		        resources << {:db_host => db_host, :schema_name => schema_name}
    		      end
    		    end
    		  end


   		    serviceDefintion = {:start_line => start_line, :end_line => end_line, :name => name, :connectors => connectors.uniq, :docBases => docBase.uniq, :resources => resources}
   		    @tomcat_services[:name] = serviceDefintion
    		end
    	end
	end
end