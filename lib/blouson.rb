require "blouson/version"

require 'blouson/sensitive_params_silencer'
require 'blouson/sensitive_query_filter'
require 'blouson/sensitive_mail_log_filter'
require 'blouson/engine'
require 'blouson/tolerant_regexp'

module Blouson
  SENSITIVE_PARAMS_REGEXP = TolerantRegexp.new('\Asecure_').freeze
  SENSITIVE_TABLE_REGEXP = /secure_/.freeze
  FILTERED = '[FILTERED]'.freeze
end
