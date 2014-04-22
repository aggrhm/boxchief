module Boxchief

  module Instrumentation

    def self.included(base)
      base.send :around_filter, :watch_request if base.respond_to?(:around_filter)
    end

    def watch_request
      t1 = Time.now
      @request_profile = {
        controller: params[:controller],
        action: params[:action]
      }
      begin
        yield
      rescue => exception
        t2 = Time.now
        @request_profile[:time] = (t2-t1) * 1000
        @request_profile[:error] = exception.message || "An error occurred"
        log_request_profile
        raise exception
      else
        t2 = Time.now
        @request_profile[:time] = (t2-t1) * 1000
        log_request_profile
      end
    end

    def log_request_profile
      Rails.logger.info "REQUEST_PROFILE: #{@request_profile.to_json}"
    end
    
  end

end
