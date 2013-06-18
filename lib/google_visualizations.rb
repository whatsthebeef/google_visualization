module GoogleVisualizations
   module Tableable

      attr_accessor :cols_def

      def tablize(models, params)
         hashes = models.map!{|m| m.attributes}.sort_by {|h| h[cols[0]]}
         return tablize_hashes(hashes, params)
      end

      def tablize_hashes(hashes, params)
         if params[:cols].to_s == ""
            cols = @cols_def.keys
         else
            cols = params[:cols].delete(" ").split(",")
         end
         hashes.sort_by! {|h| h[cols[0]]}
         if params[:type] == "discrete"
            return self.discrete_with_cols(hashes, cols)
         else
            return self.continuous_with_cols(hashes, cols)
         end
      end


      def discrete_with_cols(hashes, cols)
         key = cols[0]
         date_key, date_unit = key.split "__"
         prev_hash = nil
         hashes.delete_if do |h|
            h[key] = format_datetime_mmyy(h[date_key]) unless date_unit.nil?
            if !prev_hash.nil? and h[key].eql? prev_hash[key]
               prev_hash.merge!(h) do |k,o,n| 
                  if k.eql?(key) or !n.respond_to?("+") then n 
                  else n+o end
               end
            else
               prev_hash = h
               false
            end
         end
         return self.hashes_to_table(hashes, cols) 
      end

      def continuous_with_cols(hashes, cols)
         key = cols[0]
         cols.each do |c|
            cumul_col = c[/cumulation\((.*)\)/, 1]
            cumulation = 0
            hashes.map do |h| 
               h[key] = format_datetime_continuous(h[key]) if c.eql?(key) 
               unless cumul_col.nil?
                  @cols_def[c] = self.cumul_col_def cumul_col
                  h[c] = cumulation += h[cumul_col] 
               end
            end
         end
         return self.hashes_to_table(hashes, cols) 
      end

      def format_datetime_mmyy(datetime)
         datetime.strftime "%m/%y"
      end

      def format_datetime_continuous(datetime) 
         "Date(#{datetime.strftime('%Y')}, #{datetime.strftime('%-m').to_i - 1}, #{datetime.strftime('%-d')}, #{datetime.strftime('%k')}, #{datetime.strftime('%M')}, #{datetime.strftime('%S')})"
      end

      def cumul_col_def(col)
         {id: "cumulation(col)", label:"#{col.humanize} Cumulation", type: "number"}
      end

      def hashes_to_table(hashes, cols)
         table = { cols: @cols_def.values_at(*cols), rows:[]}
         hashes.each do |hash|
            row = {}
            row[:c] = hash.values_at(*cols).map{|v| {v:v}}
            table[:rows] << row
         end
         return table
      end
   end
end
