module Shirinji
  module Utils
    module String
      module_function

      def camelcase(str)
        chunks = str.to_s.split('_').map do |w|
          w = w.downcase
          w[0] = w[0].upcase
          w
        end

        chunks.join
      end
    end
  end
end
