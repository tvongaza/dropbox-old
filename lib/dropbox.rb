require 'dropbox/dropbox'

## Should I include this?
require 'delegate'
 
# Allows percentages to be inspected and stringified in human
# form "33.3%", but kept in a float format for mathmatics
class Percentage < DelegateClass(Float)
  def to_s(decimalplaces = 0)
    (((self * 10**(decimalplaces+2)).round)/10**decimalplaces).to_s+"%"
  end
  alias :inspect :to_s
end

