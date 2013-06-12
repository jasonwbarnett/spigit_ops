require 'nokogiri'

module SpigitOps
  class Tomcat
    def initialize(serverxml_filename = SpigitOps::TC_SERVER_XML, options= {})
      @serverxml_filename = serverxml_filename

      if ! FileTest.exist? @serverxml_filename
  			$stderr.puts "#{@serverxml_filename} doesn't exist, exiting..."
  			exit
			elsif ! FileTest.readable? @serverxml_filename
  			$stderr.puts "#{@serverxml_filename} isn't readable, exiting..."
  			exit
	  	end

	  	@serverxml_xml = Nokogiri::XML(File.open(@serverxml_filename))
      build_tomcat_services
	  end

	  def services
	  	puts @tomcat_services
	  end

    def service(name)
      puts @tomcat_services[name]
    end

    def serverxml_filename
      puts @serverxml_filename
    end

    def save!(output_filename = SpigitOps::TC_SERVICES_FILE)
      File.open(output_filename, 'w') { |f| @tomcat_services.each { |key, value| f.puts value } }
    end

	  private

      ## Create a table so we can lookup the line number for the </Service> for the particular service we want
      def build_service_end_line_lookup
        lines = File.open(@serverxml_filename).readlines.collect { |x| x.strip }
        lines.unshift('placing item in array so the index reflects the actual line number')

        services_start = (0 .. lines.count - 1).find_all { |x| lines[x,1].to_s.match(/<Service/) }
        services_end   = (0 .. lines.count - 1).find_all { |x| lines[x,1].to_s.match(/<\/Service/) }
        service_line_numbers = services_start.zip(services_end)

        @service_end_line_lookup = service_line_numbers.inject({}) do |result, element|
          key   = element.first
          value = element.last
          result[key] = value
          result
        end
      end

    	def build_tomcat_services
        build_service_end_line_lookup
        @tomcat_services = {}
    		@serverxml_xml.xpath('//Service').each do |service|
    		  name = service[:name]
    		  start_line = service.line
    		  end_line   = @service_end_line_lookup[start_line]

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
   		    @tomcat_services[name] = serviceDefintion
    		end

        @tomcat_services
    	end
	end
end