require "spigit_ops/version"
require "spigit_ops/tomcat"
require "spigit_ops/spigit_conf"

module SpigitOps
	TCS_START = 0
	TCS_END   = 1
	
	TC_SERVER_XML    = '/opt/tomcat/conf/server.xml'
	TC_SERVICES_FILE = '/spigit/data_warehouse/tomcat/services.txt'
end
