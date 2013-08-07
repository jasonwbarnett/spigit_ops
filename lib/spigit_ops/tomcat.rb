require 'nokogiri'

module SpigitOps
  class Tomcat
    def initialize(serverxml_filename = SpigitOps::TC_SERVER_XML, options= {})
      @serverxml_filename = serverxml_filename

      if ! FileTest.exist? @serverxml_filename
  			raise "#{@serverxml_filename} doesn't exist."
			elsif ! FileTest.readable? @serverxml_filename
        raise "#{@serverxml_filename} isn't readable."
	  	end

	  	@serverxml_xml = Nokogiri::XML(File.open(@serverxml_filename))
      build_tomcat_services
	  end

	  def services
	  	puts @tomcat_services
	  end

    def count
      puts @tomcat_services.length
    end

    def exist?(service)

    end

    def grab_service(name)
      puts @tomcat_services[name]
    end

    def serverxml_filename
      puts @serverxml_filename
    end

    def save!(output_filename = SpigitOps::TC_SERVICES_FILE, options = {})
      format = options[:format]

      if format == 'old'
        File.open(output_filename, 'w') { |f| @old_tomcat_services.each { |x| f.puts x } }
      else
        File.open(output_filename, 'w') { |f| @tomcat_services.each { |key, value| f.puts value } }
      end
    end

    def save_old!(output_filename = SpigitOps::TC_SERVICES_FILE)
      self.save!(output_filename, format: 'old')
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
        @tomcat_services       = {}
        @old_tomcat_services   = []

        ## Loop to grab all information from the server.xml
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
    		    db_host     = resource[:url].scan(%r{mysql://(.*)/}).join.sub(/^127\.0\.0\.1$/, "localhost") if String === resource[:url]
    		    schema_name = resource[:url].scan(%r{/([^/]+)\?}).join if String === resource[:url]

    		    if resources.empty?
    		      resources << {:db_host => db_host, :schema_name => schema_name} if db_host and schema_name
              resources << {:db_host => db_host, :schema_name => "#{schema_name}user"} if resources.length > 0
    		    else
              ## This checks to see if the result
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

          ## This finishes things up and creates a hash for all tomcat services
          serviceDefintion = {:start_line => start_line, :end_line => end_line, :name => name, :connectors => connectors.uniq, :docBases => docBase.uniq, :resources => resources}
          @tomcat_services[name] = serviceDefintion

                  ## This is all for the OLD/ORIGINAL output ##
                  # Create schemas array for all schema names, then add NAMEuser schema.
                  old_schemas = resources.inject([]) do |result, resource|
                    result << resource[:schema_name]
                    result
                  end

                  # Create dbhost variable and check some stuff out
                  old_db_hosts = resources.inject([]) do |result, resource|
                    result << resource[:db_host]
                    result
                  end.uniq
                  if old_db_hosts.count > 1
                    puts "WARNING: We found miltiple hosts for the schema's, exiting..."
                    exit 1
                  end

                  # Create ips array for all ip addresses
                  old_ips = connectors.inject([]) do |result, connector|
                    result << connector[:ip]
                    result
                  end
                  old_serviceDefintion = "#{start_line},#{end_line}:#{old_ips.uniq.join(',')}:#{docBase.uniq.join(',')}:#{old_db_hosts.join(',')}:#{old_schemas.join(',')}:#{name}"
                  @old_tomcat_services << old_serviceDefintion
                  ## This is all for the OLD/ORIGINAL output ##
        end
      @tomcat_services
    end
	end
end