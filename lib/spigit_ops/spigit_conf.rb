module SpigitOps
  class SpigitConf
      def initialize(xml)
          @spigit_conf  = Nokogiri::XML(File.open(xml, 'r').read)
      end

  end
end
