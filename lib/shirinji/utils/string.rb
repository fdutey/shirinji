module Shirinji
  module Utils
    module String
      CAMEL =
        /[a-z][A-Z]|[A-Z]{2,}[a-z]|[0-9][a-zA-Z]|[a-zA-Z][0-9]|[^a-zA-Z0-9 ]/

      module_function

      def camelcase(str)
        chunks = str.to_s.split('_').map do |w|
          w = w.downcase
          w[0] = w[0].upcase
          w
        end

        chunks.join
      end

      def snakecase(str)
        str.gsub(CAMEL) { |s| s.split('').join('_') }.downcase
      end
    end
  end
end
