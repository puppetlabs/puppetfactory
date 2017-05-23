class String
  if not String.method_defined? :snake_case
     def snake_case!
       gsub!(/(.)([A-Z])/,'\1_\2')
       downcase!
     end

     def snake_case
       dup.tap { |s| s.snake_case! }
     end
  end

  if not String.method_defined? :trim
    def trim(size)
      if self.size > size
        "#{self[0...(size - 1)]}…"
      else
        self
      end
    end
  end
end

class Symbol
  if not Symbol.method_defined? :snake_case
     def snake_case
       to_s.snake_case.to_sym
     end
  end
end
