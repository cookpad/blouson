module Blouson
  class TolerantRegexp < Regexp
    def =~(str)
      if str.respond_to?(:valid_encoding?) && !str.valid_encoding?
        nil
      else
        super
      end
    end
  end
end
